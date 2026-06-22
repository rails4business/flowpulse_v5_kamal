module CreatorWorld
  class DashboardController < BaseController
    dashboard_section :creator

    def show
      @creator_assignments = creator_assignments
        .includes(nodes: :domains)
        .order(:id)
    end

    private

      def creator_assignments
        scope = RoleAssignment.where(role: :creator_of_worlds)
        return scope if superadmin_user?

        Current.user.role_assignments.where(role: :creator_of_worlds)
      end
  end
end
