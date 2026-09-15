module Demo
  class BaseController < ApplicationController
    before_action :require_demo_access!
    before_action :require_demo_read_only!

    private

    def require_demo_access!
      unless Current.user&.superadmin_user? && active_dashboard_role == "superadmin"
        redirect_to root_path, alert: "Accesso riservato al superadmin."
      end
    end

    def require_demo_read_only!
      return if request.get? || request.head?

      redirect_to demo_viaggiatori_path, alert: "La demo e solo in lettura."
    end
  end
end
