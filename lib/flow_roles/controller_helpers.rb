module FlowRoles
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :superadmin?, :superadmin_user?, :admin_user?, :demo_mode?,
        :ideatore_user?, :creator_user?, :digital_user?, :responsabile_user?,
        :active_dashboard_role, :active_dashboard_role_label, :dashboard_home_path,
        :ruolo_label
    end

    private

      def ruolo_label(role_key)
        FlowRoles.label(role_key)
      end

      def superadmin?
        superadmin_user?
      end

      def superadmin_user?
        Current.user&.superadmin_user? || false
      end

      def admin_user?
        Current.user&.admin_user? || false
      end

      def demo_mode?
        false
      end

      def creator_user?
        Current.user&.creator_user? || false
      end

      def teacher_user?
        operator_access?("teacher", "insegnante")
      end

      def tutor_user?
        operator_access?("tutor")
      end

      def professional_user?
        operator_access?("professional", "professionista")
      end

      def operator_access?(*operator_roles)
        Current.user&.role_assignments&.where(role: :operator, role_operator: operator_roles).exists? || false
      end

      def active_dashboard_role
        FlowRoles.active_role_for(Current.user)
      end

      def active_dashboard_role_label
        ruolo_label(active_dashboard_role)
      end

      def dashboard_home_path
        FlowRoles.dashboard_path_for(Current.user, self)
      end

      def require_role!(role, context = nil)
        return if FlowRoles.can?(Current.user, :read, role, context: context)

        redirect_to dashboard_home_path, alert: "Accesso riservato al ruolo #{ruolo_label(role)}."
      end

      def require_permission!(resource, action = :read)
        return if FlowRoles.can?(Current.user, action, resource)

        redirect_to dashboard_home_path, alert: "Accesso non disponibile per il ruolo attivo."
      end

      def require_not_demo_mode!
        return unless demo_mode?

        redirect_to admin_dashboard_path, alert: "Le demo sono riservate al superadmin."
      end
  end
end
