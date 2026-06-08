module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      unless admin_user? && (superadmin_user? || !demo_mode?)
        redirect_to root_path, alert: "Accesso riservato agli admin."
      end
    end

    def require_superadmin!
      unless superadmin_user?
        redirect_to root_path, alert: "Accesso riservato ai superadmin."
      end
    end
  end
end
