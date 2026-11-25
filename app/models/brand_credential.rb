class BrandCredential < ApplicationRecord
  STATUSES = %w[active pending_verification suspended revoked].freeze

  belongs_to :brand_access
  belongs_to :brand_node, class_name: "Node"
  has_many :sessions, dependent: :nullify

  has_secure_password

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { scope: :brand_node_id }
  validates :brand_access_id, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validate :brand_matches_access

  scope :active, -> { where(status: "active") }

  def active?
    status == "active" && brand_access.active?
  end

  def record_authentication!
    update!(last_authenticated_at: Time.current)
  end

  private

    def brand_matches_access
      return if brand_access.blank? || brand_node.blank?
      return if brand_access.brand_node_id == brand_node_id

      errors.add(:brand_node, "deve corrispondere al BrandAccess")
    end
end
