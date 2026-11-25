class PlatformCredential < ApplicationRecord
  belongs_to :profile
  has_many :sessions, dependent: :nullify

  has_secure_password

  enum :status, {
    active: "active",
    suspended: "suspended",
    revoked: "revoked"
  }, default: :active, validate: true

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  def record_authentication!
    touch(:last_authenticated_at)
  end
end
