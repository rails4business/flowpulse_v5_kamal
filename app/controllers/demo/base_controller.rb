module Demo
  class BaseController < ApplicationController
    before_action :require_demo_access!
    before_action :require_demo_read_only!

    private

    def require_demo_access!
      user = Current.user
      unless superadmin_user? || user&.has_demo_access?
        redirect_to root_path, alert: "Accesso riservato agli utenti demo."
      end
    end

    def require_demo_read_only!
      return if request.get? || request.head?

      redirect_to demo_viaggiatori_path, alert: "La demo e solo in lettura."
    end
  end
end
