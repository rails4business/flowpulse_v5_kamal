class Session < ApplicationRecord
  DEFAULT_DURATION = 60.days

  belongs_to :user
  belongs_to :profile, optional: true
  belongs_to :brand_access, optional: true
  belongs_to :brand_credential, optional: true
  belongs_to :platform_credential, optional: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  before_validation :set_defaults, on: :create

  validates :authenticated_at, :expires_at, presence: true
  validate :brand_access_belongs_to_user
  validate :brand_credential_matches_session
  validate :profile_matches_user
  validate :platform_credential_matches_session

  def active?
    revoked_at.nil? &&
      expires_at.future? &&
      (brand_access.nil? || brand_access.active?) &&
      (brand_credential.nil? || brand_credential.active?) &&
      (platform_credential.nil? || platform_credential.active?)
  end

  def valid_for?(domain)
    return false unless active?
    return true if user&.superadmin_user?
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
      self.profile ||= user&.profile
    end

    def brand_access_belongs_to_user
      return if brand_access.blank?
      return if user&.profile&.id == brand_access.profile_id

      errors.add(:brand_access_id, "deve appartenere allo stesso utente della sessione")
    end

    def brand_credential_matches_session
      return if brand_credential.blank?

      errors.add(:brand_access_id, "deve essere presente per una credenziale Brand") if brand_access.blank?
      if brand_access.present? && brand_credential.brand_access_id != brand_access_id
        errors.add(:brand_credential_id, "deve appartenere al BrandAccess della sessione")
      end
      if user&.profile&.id != brand_credential.brand_access.profile_id
        errors.add(:brand_credential_id, "deve appartenere allo stesso profilo")
      end
    end

    def profile_matches_user
      return if profile.blank? || profile.user_id == user_id

      errors.add(:profile_id, "deve appartenere allo stesso User della sessione durante la transizione")
    end

    def platform_credential_matches_session
      return if platform_credential.blank?

      if profile.blank?
        errors.add(:profile_id, "deve essere presente per una credenziale di piattaforma")
      elsif platform_credential.profile_id != profile_id
        errors.add(:platform_credential_id, "deve appartenere al Profile della sessione")
      end
      if brand_access.present? || brand_credential.present?
        errors.add(:platform_credential_id, "non può essere combinata con credenziali Brand")
      end
    end
end
