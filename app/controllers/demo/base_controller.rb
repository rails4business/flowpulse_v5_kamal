module Demo
  class BaseController < ApplicationController
    before_action :require_demo_access!

    private

    def require_demo_access!
      user = Current.user
      unless user&.superadmin? || user&.demo_access?
        redirect_to root_path, alert: "Accesso riservato agli utenti demo."
      end
    end
  end
end
