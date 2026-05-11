module Admin
  class BaseController < ApplicationController
    before_action :require_superadmin!

    private

    def require_superadmin!
      unless Current.user&.superadmin?
        redirect_to root_path, alert: "Accesso riservato ai superadmin."
      end
    end
  end
end
