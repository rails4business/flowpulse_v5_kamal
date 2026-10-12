class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  include FlowRoles::UserRoles

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :email_verifications, dependent: :destroy
  has_many :sent_brand_invitations,
    class_name: "BrandInvitation",
    foreign_key: :invited_by_user_id,
    dependent: :restrict_with_error
  has_many :accepted_brand_invitations,
    class_name: "BrandInvitation",
    foreign_key: :accepted_by_user_id,
    dependent: :nullify
  has_many :password_reset_requests, dependent: :destroy
  belongs_to :current_role_assignment, class_name: "RoleAssignment", optional: true
  accepts_nested_attributes_for :profile

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  REGISTRATION_STATUSES = %w[pending_email_verification active suspended].freeze
  validates :registration_status, inclusion: { in: REGISTRATION_STATUSES }

  def email_verified?
    email_verified_at.present?
  end

  def active_registration?
    registration_status == "active"
  end

  def activate_verified_email!
    update!(email_verified_at: Time.current, registration_status: "active")
  end


  enum :active_role, {
    traveler: 0,
    admin: 6,
    superadmin: 7,
    ideatore: 8,
    creator: 9,
    digital: 10
  }

  ROLE_LABELS = {
    "traveler" => "Viaggiatore",
    "ideatore" => "Ideatore",
    "creator" => "Creator",
    "digital" => "Digital",
    "admin" => "Admin",
    "superadmin" => "Superadmin"
  }.freeze

  SWITCHABLE_ROLES = %w[
    traveler
    ideatore
    creator
    digital
    admin
    superadmin
  ].freeze
end
