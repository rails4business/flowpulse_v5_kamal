module FlowRoles
  module UserRoles
    extend ActiveSupport::Concern

    included do
      has_many :role_assignments, through: :profile, dependent: :destroy
    end

    def can_activate_role?(role_name)
      role = role_name.to_s
      self.class.active_roles.key?(role) && ruoli_attivabili.include?(role)
    end

    def safe_active_role
      can_activate_role?(active_role) ? active_role : "traveler"
    end

    def active_role_attivabile?
      can_activate_role?(active_role)
    end

    def ruoli_attivabili
      attivabili = [ "traveler" ]
      attivabili << "superadmin" if superadmin_user?
      attivabili.concat(assigned_role_names)
      self.class::SWITCHABLE_ROLES & attivabili.uniq
    end

    def assigned_role_names(context = nil)
      assignments = context.present? ? role_assignments.for_context(context) : role_assignments.global
      assignments.pluck(:role).map do |r|
        case r
        when "creator_of_worlds" then "creator"
        when "segreteria_amministrativa" then "admin"
        else r
        end
      end
    end

    def has_assigned_role?(role_name, context = nil)
      role = role_name.to_s
      role = "creator_of_worlds" if role == "creator"
      role = "segreteria_amministrativa" if role == "admin"
      return true if superadmin_user?
      return false unless RoleAssignment.roles.key?(role)

      assignments = context.present? ? role_assignments.for_context(context) : role_assignments.global
      assignments.where(role: role).exists?
    end

    def superadmin_user?
      self[:superadmin] == true || self[:superadmin] == 1
    end

    def admin_user?
      has_assigned_role?("admin")
    end

    def creator_user?(context = nil)
      has_assigned_role?("creator", context)
    end

    def teacher_user?(context = nil)
      has_assigned_role?("teacher", context)
    end

    def tutor_user?(context = nil)
      has_assigned_role?("tutor", context)
    end

    def professional_user?(context = nil)
      has_assigned_role?("professional", context)
    end

    def is_superadmin?
      superadmin_user?
    end

    def has_demo_access?
      superadmin_user? || role_assignments.where(role: "demo").exists?
    end

    def can_switch_roles?
      superadmin_user? || ruoli_attivabili.size > 1
    end
  end
end
