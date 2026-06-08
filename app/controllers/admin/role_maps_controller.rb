module Admin
  class RoleMapsController < BaseController
    dashboard_section :role_map

    before_action :require_superadmin!

    def show
      @roles = User::SWITCHABLE_ROLES
      @menu_items = FlowRoles::MenuRegistry.items
    end
  end
end
