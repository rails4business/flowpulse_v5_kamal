class User < ApplicationRecord
  has_secure_password
  has_one :profile, dependent: :destroy
  has_many :sessions, dependent: :destroy
  accepts_nested_attributes_for :profile

  normalizes :email_address, with: ->(e) { e.strip.downcase }


  enum :active_role, {
    traveler: 0,
    demo: 1,
    creator: 2,
    operator: 3,
    professional: 4,
    admin: 5,
    superadmin: 6
  }
 
  def can_activate_role?(role)
    available_active_roles.include?(role.to_s)
  end
end
