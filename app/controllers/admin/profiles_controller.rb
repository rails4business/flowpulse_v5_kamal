module Admin
  class ProfilesController < BaseController
    before_action :require_superadmin!

    def show
      @profile = Profile.includes(:user, :primary_node).find(params[:id])
      @brand_accesses = @profile.brand_accesses.includes(:brand_node, :source_domain).order(:status, :joined_at, :id)
      @role_assignments = @profile.role_assignments
        .includes(:context, :parent, :brand_access, :assigned_by_profile)
        .order(:role, :role_operator, :created_at)
      @context_nodes = @role_assignments.filter_map { |assignment| assignment.context if assignment.context.is_a?(Node) }.uniq
      @owned_nodes = Node.where(role_assignment_id: @role_assignments.select(:id)).order(:title)
      @genera_impresa = Node.find_by(slug: "generaimpresa")
      @creator_assignment = @role_assignments.find do |assignment|
        assignment.operator? && assignment.role_operator == "imprenditore_generaimpresa" && assignment.context == @genera_impresa && assignment.status == "active"
      end
      @available_domains = Domain.active.where.not(node_id: nil).includes(:node).order(:hostname)
      active_accesses = @brand_accesses.select(&:active?)
      accessible_node_ids = active_accesses.flat_map { |access| access.brand_node.self_and_descendants.pluck(:id) }.uniq
      brand_node_ids = active_accesses.map(&:brand_node_id)
      @responsibility_nodes = Node.where(id: accessible_node_ids).where.not(id: brand_node_ids).order(:title)
      @responsibility_role_options = RoleDefinitions::Registry.all.select do |definition|
        active_accesses.any? { |access| RoleDefinitions::Registry.compatible_with_brand?(definition.code, access.brand_node) }
      end
    end
  end
end
