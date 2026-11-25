class SystemRoleAssignment < ApplicationRecord
  ROLE_CODES = %w[superadmin].freeze

  belongs_to :profile
  belongs_to :assigned_by_profile, class_name: "Profile", optional: true

  enum :status, {
    active: "active",
    suspended: "suspended",
    revoked: "revoked"
  }, default: :active, validate: true

  validates :role_code, presence: true, inclusion: { in: ROLE_CODES }, uniqueness: { scope: :profile_id }

  scope :currently_effective, -> {
    active
      .where("starts_at IS NULL OR starts_at <= ?", Time.current)
      .where("ends_at IS NULL OR ends_at > ?", Time.current)
  }
  scope :superadmin, -> { where(role_code: "superadmin") }
end
