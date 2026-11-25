module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      return if Current.user&.superadmin_user?

      require_permission!(:admin)
    end

    def require_superadmin!
      return if Current.user&.superadmin_user?

      redirect_to dashboard_home_path, alert: "Accesso riservato al superadmin."
    end
  end
end
