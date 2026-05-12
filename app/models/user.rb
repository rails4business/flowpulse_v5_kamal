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

  def can_activate_role?(role_name)
    ruoli_attivabili.include?(role_name.to_s)
  end

  def ruoli_attivabili
    # Controllo super-robusto per superadmin
    is_sa = (self[:superadmin] == true || self[:superadmin] == 1 || superadmin == true)
    is_demo = (self[:demo_access] == true || self[:demo_access] == 1 || demo_access == true)

    attivabili = ["traveler"]
    attivabili << "demo" if is_demo
    attivabili << "superadmin" if is_sa
    attivabili.uniq
  end

  # Helper rapidi per i permessi di base
  def is_superadmin?
    superadmin?
  end

  def has_demo_access?
    superadmin? || demo_access?
  end

  def can_switch_roles?
    superadmin? || ruoli_attivabili.size > 1
  end
end
