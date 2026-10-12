class Session < ApplicationRecord
  DEFAULT_DURATION = 60.days

  belongs_to :user
  belongs_to :brand_access, optional: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  before_validation :set_defaults, on: :create

  validates :authenticated_at, :expires_at, presence: true
  validate :brand_access_belongs_to_user

  def active?
    revoked_at.nil? && expires_at.future? && (brand_access.nil? || brand_access.active?)
  end

  def valid_for?(domain)
    return false unless active?
    return brand_access.nil? if domain.blank?

    requested_node = domain.resolved_node
    return brand_access.nil? if requested_node.blank?

    brand_access&.brand_node_id == requested_node.id
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

    def set_defaults
      self.authenticated_at ||= Time.current
      self.expires_at ||= DEFAULT_DURATION.from_now
      self.authentication_method ||= "password"
    end

    def brand_access_belongs_to_user
      return if brand_access.blank?
      return if user&.profile&.id == brand_access.profile_id

      errors.add(:brand_access_id, "deve appartenere allo stesso utente della sessione")
    end
end
