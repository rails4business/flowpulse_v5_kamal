module Admin
  class ProfilesController < BaseController
    before_action :require_superadmin!

    def index
      @profiles = Profile
        .includes(:user, :primary_node, :brand_accesses, :role_assignments)
        .order(:username)
    end

    def show
      @profile = Profile.includes(:user, :primary_node).find(params[:id])
      @role_assignments = @profile.role_assignments
        .includes(:context, :parent, :brand_access, :assigned_by_profile)
        .order(:role, :role_operator, :created_at)
      @genera_impresa = Node.find_by(slug: "generaimpresa")
      @genera_impresa_assignments = @role_assignments.select do |assignment|
        assignment.operator? && assignment.context == @genera_impresa && assignment.status == "active"
      end.index_by(&:role_operator)
    end
  end
end
