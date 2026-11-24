module Admin
  class ProfilesController < BaseController
    before_action :require_superadmin!

    def show
      @profile = Profile.includes(:user, :primary_node, :brand_accesses).find(params[:id])
      @role_assignments = @profile.role_assignments.includes(:context, :parent).order(:role, :role_operator, :created_at)
      @context_nodes = @role_assignments.filter_map { |assignment| assignment.context if assignment.context.is_a?(Node) }.uniq
      @owned_nodes = Node.where(role_assignment_id: @role_assignments.select(:id)).order(:title)
      @genera_impresa = Node.find_by(slug: "generaimpresa")
      @creator_assignment = @role_assignments.find do |assignment|
        assignment.operator? && assignment.role_operator == "creator_generaimpresa" && assignment.context == @genera_impresa
      end
    end
  end
end
