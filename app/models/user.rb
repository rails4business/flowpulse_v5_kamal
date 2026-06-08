class User < ApplicationRecord
  include FlowRoles::UserRoles

  has_secure_password
  has_one :profile, dependent: :destroy
  has_many :sessions, dependent: :destroy
  accepts_nested_attributes_for :profile

  normalizes :email_address, with: ->(e) { e.strip.downcase }


  enum :active_role, {
    traveler: 0,
    demo: 1,
    creator: 2,
    tutor: 3,
    teacher: 4,
    professional: 5,
    admin: 6,
    superadmin: 7
  }

  ROLE_LABELS = {
    "traveler" => "Viaggiatore",
    "demo" => "Demo",
    "creator" => "Creator",
    "teacher" => "Teacher",
    "tutor" => "Tutor",
    "professional" => "Professionista",
    "admin" => "Admin",
    "superadmin" => "Superadmin"
  }.freeze

  SWITCHABLE_ROLES = %w[
    traveler
    demo
    creator
    teacher
    tutor
    professional
    admin
    superadmin
  ].freeze
end
