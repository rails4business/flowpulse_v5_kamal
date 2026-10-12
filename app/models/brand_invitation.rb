class BrandInvitation < ApplicationRecord
  EXPIRATION = 7.days
  STATUSES = %w[pending accepted revoked].freeze

  belongs_to :brand_node, class_name: "Node"
  belongs_to :source_domain, class_name: "Domain", optional: true
  belongs_to :invited_by_user, class_name: "User"
  belongs_to :accepted_by_user, class_name: "User", optional: true

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true
  validate :brand_node_is_a_brand
  validate :source_domain_matches_brand

  scope :pending, -> { where(status: "pending").where("expires_at > ?", Time.current) }

  def self.issue!(brand_node:, email_address:, invited_by_user:, source_domain: nil, role_code: nil)
    raw_token = SecureRandom.urlsafe_base64(32)
    invitation = create!(
      brand_node:,
      source_domain:,
      email_address:,
      invited_by_user:,
      role_code:,
      token_digest: digest(raw_token),
      expires_at: EXPIRATION.from_now
    )
    [invitation, raw_token]
  end

  def self.find_pending_by_token(raw_token)
    pending.find_by(token_digest: digest(raw_token.to_s))
  end

  def pending?
    status == "pending" && expires_at.future?
  end

  def accept!(user)
    raise ActiveRecord::RecordInvalid, self unless pending?
    unless user.email_address.casecmp?(email_address)
      errors.add(:email_address, "deve coincidere con l’account invitato")
      raise ActiveRecord::RecordInvalid, self
    end

    update!(status: "accepted", accepted_by_user: user, accepted_at: Time.current)
  end

  def self.digest(raw_token)
    OpenSSL::Digest::SHA256.hexdigest(raw_token)
  end

  private

    def brand_node_is_a_brand
      errors.add(:brand_node, "deve essere un Brand") unless brand_node&.brand?
    end

    def source_domain_matches_brand
      return if source_domain.blank? || source_domain.node_id == brand_node_id

      errors.add(:source_domain, "deve appartenere al Brand invitante")
    end
end
