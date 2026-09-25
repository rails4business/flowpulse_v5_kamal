class DomainMembership < ApplicationRecord
  STATUSES = %w[active cancelled].freeze

  belongs_to :profile
  belongs_to :domain

  validates :status, inclusion: { in: STATUSES }
  validates :domain_id, uniqueness: { scope: :profile_id }

  before_validation :set_defaults

  scope :active, -> { where(status: "active") }

  def active?
    status == "active"
  end

  def cancel!
    update!(status: "cancelled")
  end

  def reactivate!
    update!(status: "active", joined_at: Time.current)
  end

  # A membership remains specific to one hostname. When that hostname belongs
  # to a Node/brand, brand access is resolved through the profile subscription
  # instead of storing a duplicate foreign key on this record.
  def traveler_subscription
    return if domain.node_id.blank?

    profile.traveler_subscriptions.active.find_by(node_id: domain.node_id)
  end

  def brand_access?
    traveler_subscription.present?
  end

  def standalone_domain?
    domain.node_id.blank?
  end

  private

    def set_defaults
      self.status = "active" if status.blank?
      self.joined_at ||= Time.current
    end
end
