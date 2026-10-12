class DomainAccess < ApplicationRecord
  STATUSES = %w[active cancelled].freeze

  belongs_to :profile
  belongs_to :domain
  belongs_to :brand_access

  before_validation :set_defaults

  validates :status, inclusion: { in: STATUSES }
  validates :domain_id, uniqueness: { scope: :profile_id }
  validates :domain_id, uniqueness: { scope: :brand_access_id }
  validate :profile_matches_brand_access
  validate :domain_matches_brand_access

  scope :active, -> { where(status: "active") }

  def active?
    status == "active"
  end

  def cancel!
    update!(status: "cancelled")
  end

  def reactivate!
    update!(status: "active", activated_at: Time.current, last_accessed_at: Time.current)
  end

  private

    def set_defaults
      self.status = "active" if status.blank?
      self.activated_at ||= Time.current
      self.last_accessed_at ||= Time.current
    end

    def profile_matches_brand_access
      return if profile.blank? || brand_access.blank?
      return if profile_id == brand_access.profile_id

      errors.add(:profile_id, "deve corrispondere al profilo dell'accesso al brand")
    end

    def domain_matches_brand_access
      return if domain.blank? || brand_access.blank?
      return if domain.node_id == brand_access.brand_node_id

      errors.add(:domain_id, "deve presentare lo stesso nodo dell'accesso al brand")
    end
end
