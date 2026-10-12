class EmailVerification < ApplicationRecord
  EXPIRATION = 30.minutes

  belongs_to :user
  belongs_to :brand_node, class_name: "Node", optional: true
  belongs_to :requested_domain, class_name: "Domain", optional: true

  scope :pending, -> { where(verified_at: nil).where("expires_at > ?", Time.current) }

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def self.issue!(user:, brand_node: nil, requested_domain: nil, return_to: nil, request_ip: nil, user_agent: nil, metadata: {})
    raw_token = SecureRandom.urlsafe_base64(32)
    transaction do
      user.email_verifications.where(verified_at: nil).update_all(expires_at: Time.current)
      verification = create!(
        user:,
        brand_node:,
        requested_domain:,
        token_digest: digest(raw_token),
        expires_at: EXPIRATION.from_now,
        return_to:,
        request_ip:,
        user_agent:,
        metadata:
      )
      [verification, raw_token]
    end
  end

  def self.find_pending_by_token(raw_token)
    pending.find_by(token_digest: digest(raw_token.to_s))
  end

  def pending?
    verified_at.nil? && expires_at.future?
  end

  def consume!
    raise ActiveRecord::RecordInvalid, self unless pending?

    update!(verified_at: Time.current)
  end

  def self.digest(raw_token)
    OpenSSL::Digest::SHA256.hexdigest(raw_token)
  end
end
