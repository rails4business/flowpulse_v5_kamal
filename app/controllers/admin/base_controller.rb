module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      require_permission!(:admin)
    end

    def require_superadmin!
      require_permission!(:superadmin)
    end
  end
end
