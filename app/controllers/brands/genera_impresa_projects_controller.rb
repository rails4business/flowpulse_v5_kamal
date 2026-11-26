module Brands
  class GeneraImpresaProjectsController < ApplicationController
    layout "application"

    before_action :require_authentication
    before_action :set_brand
    before_action :require_projects_access!
    before_action :set_node, only: :update

    def index
      load_workspace
    end

    def create
      parent = accessible_nodes.find(params.require(:parent_id))
      node = NodeManagement::Manager.new(actor: Current.user, context: dashboard_access_context).create_child!(parent: parent, attributes: node_params)
      redirect_to genera_impresa_my_projects_path, notice: "#{node.title} creato."
    rescue ActiveRecord::RecordInvalid, NodeManagement::Manager::NotAuthorized => error
      redirect_to genera_impresa_my_projects_path, alert: error.message
    end

    def update
      NodeManagement::Manager.new(actor: Current.user, context: dashboard_access_context).update!(node: @node, attributes: node_params)
      redirect_to genera_impresa_my_projects_path, notice: "#{@node.title} aggiornato."
    rescue ActiveRecord::RecordInvalid, NodeManagement::Manager::NotAuthorized => error
      redirect_to genera_impresa_my_projects_path, alert: error.message
    end

    private

      def set_brand
        @brand = Node.find_by!(slug: "generaimpresa")
      end

      def require_projects_access!
        head :forbidden unless DashboardNavigation::Policy.new(context: dashboard_access_context).allowed?(:projects)
      end

      def set_node
        @node = accessible_nodes.find(params[:id])
      end

      def accessible_nodes
        scope = @brand.self_and_descendants.where.not(id: @brand.id)
        policy = DashboardNavigation::Policy.new(context: dashboard_access_context)
        candidates = if policy.full_brand_access? || dashboard_access_context.capability?(:manage_projects)
          scope
        else
          scope.where(responsible_profile: Current.user.profile)
        end
        permitted_ids = candidates.select do |node|
          node.site_node == @brand && (policy.full_brand_access? ||
            RoleAssignments::AccessPolicy.allowed?(user: Current.user, action: :manage, node: node, context: dashboard_access_context))
        end.map(&:id)
        scope.where(id: permitted_ids)
      end

      def load_workspace
        @nodes = accessible_nodes.includes(:parent, :domains).order(:depth, :position, :title)
        @parents = @nodes.select do |node|
          RoleAssignments::AccessPolicy.can_create_node?(user: Current.user, parent: node, context: dashboard_access_context)
        end
        @managed_count = if Current.user.superadmin_user?
          @nodes.where.not(responsible_profile_id: nil).count
        else
          @nodes.count
        end
        @managed_limit = if dashboard_access_context.current_role_code == "imprenditore_generaimpresa"
          RoleDefinitions::Registry.fetch("imprenditore_generaimpresa").limits[:managed_nodes_per_brand]
        end
      end

      def node_params
        params.require(:node).permit(:title, :description, :status, :visibility)
      end
  end
end
