module FlowRoles
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :superadmin?, :superadmin_user?, :admin_user?, :demo_mode?,
        :creator_user?, :teacher_user?, :tutor_user?, :professional_user?,
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
        active_dashboard_role == "demo"
      end

      def creator_user?
        Current.user&.creator_user? || false
      end

      def teacher_user?
        Current.user&.teacher_user? || false
      end

      def tutor_user?
        Current.user&.tutor_user? || false
      end

      def professional_user?
        Current.user&.professional_user? || false
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
        return if Current.user&.has_assigned_role?(role, context)

        redirect_to dashboard_home_path, alert: "Accesso riservato al ruolo #{ruolo_label(role)}."
      end

      def require_not_demo_mode!
        return unless demo_mode?

        redirect_to dashboard_home_path, alert: "La demo e solo in lettura."
      end
  end
end
