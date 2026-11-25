module Admin
  class ProfileNodesController < BaseController
    before_action :require_superadmin!
    before_action :set_profile

    def index
      @nodes = associated_nodes.includes(:domains, :responsible_profile).order(:title)
      @brand_accesses = @profile.brand_accesses.active.includes(:brand_node)
      accessible_node_ids = @brand_accesses.flat_map { |access| access.brand_node.self_and_descendants.pluck(:id) }.uniq
      brand_node_ids = @brand_accesses.map(&:brand_node_id)
      @responsibility_nodes = Node.where(id: accessible_node_ids).where.not(id: brand_node_ids).order(:title)
      @responsibility_role_options = RoleDefinitions::Registry.all.select do |definition|
        @brand_accesses.any? { |access| RoleDefinitions::Registry.compatible_with_brand?(definition.code, access.brand_node) }
      end
    end

    def show
      @node = associated_nodes.includes(:domains, :parent, :responsible_profile).find(params[:id])
      @role_assignments = @profile.role_assignments.where(context: @node)
        .includes(:brand_access, :assigned_by_profile)
        .order(:role_operator, :created_at)
    end

    private

      def set_profile
        @profile = Profile.includes(:user, :primary_node).find(params[:profile_id])
      end

      def associated_nodes
        assignment_ids = @profile.role_assignments.select(:id)
        context_node_ids = @profile.role_assignments.where(context_type: "Node").select(:context_id)
        node_ids = Node.where(role_assignment_id: assignment_ids).select(:id)
          .or(Node.where(id: context_node_ids).select(:id))
          .or(@profile.responsible_nodes.select(:id))
        node_ids = node_ids.or(Node.where(id: @profile.primary_node_id).select(:id)) if @profile.primary_node_id
        Node.where(id: node_ids)
      end
  end
end
