module Admin
  class BrandsController < BaseController
    dashboard_section :brands

    before_action :require_superadmin!
    before_action :set_node, only: :show

    def index
      @active_tab = params[:tab].presence_in(%w[brands domains]) || "brands"

      if @active_tab == "domains"
        @domains = Domain.includes(:node, :role_assignment).order(:hostname)
      else
        @brands = Node.joins(:domains)
          .distinct
          .preload(:domains, :role_assignment, :parent)
          .order(:title, :id)
      end
    end

    def show
      @active_tab = params[:tab].presence_in(%w[tree info]) || "tree"
      @children = @node.children.includes(:domains, :link_node, :role_assignment).order(:position, :title)
      @domains = @node.domains.order(:hostname)
      @ancestors = @node.ancestors.order(:depth, :position, :title)
      @tree_nodes = @node.self_and_descendants.includes(:domains, :link_node, :role_assignment, :professional_owner_node).order(:position, :title, :id).to_a
      @tree_nodes_by_parent_id = @tree_nodes.group_by(&:parent_id)
    end

    private

    def set_node
      @node = Node.includes(:domains, :link_node, :role_assignment, :parent).find(params[:id])
    end
  end
end
