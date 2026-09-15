class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  include FlowRoles::UserRoles

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :password_reset_requests, dependent: :destroy
  belongs_to :current_role_assignment, class_name: "RoleAssignment", optional: true
  accepts_nested_attributes_for :profile

  normalizes :email_address, with: ->(e) { e.strip.downcase }


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
