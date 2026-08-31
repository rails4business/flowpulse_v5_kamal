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

  private

    def set_defaults
      self.status = "active" if status.blank?
      self.joined_at ||= Time.current
    end
end
