module Brands
  module Admin
    class NodesController < ::Admin::BaseController
      before_action :require_superadmin!
      before_action :set_brand
      before_action :set_node, only: %i[show update destroy]

      def index
        @active_view = params[:view] == "schema" ? "schema" : "list"
        @nodes = @brand.self_and_descendants
          .includes(:brand_processes, :link_node)
          .order(:position, :title, :id)
          .to_a
        @nodes_by_parent_id = @nodes.group_by(&:parent_id)
        load_form_options
      end

      def show
        @processes = @node.brand_processes.order(:title)
        load_form_options
      end

      def create
        parent = @brand.self_and_descendants.find(node_params.delete(:parent_id).presence || @brand.id)
        node = Node.new(node_params.merge(parent: parent, role_assignment: @brand.role_assignment, node_type: :project))

        if node.save
          redirect_to brand_admin_node_path(@brand.slug, node), notice: "Nodo creato."
        else
          redirect_to brand_admin_nodes_path(@brand.slug), alert: node.errors.full_messages.to_sentence
        end
      end

      def update
        attributes = node_params
        parent_id = attributes.delete(:parent_id)
        @node.parent = @brand.self_and_descendants.where.not(id: @node.self_and_descendants.select(:id)).find(parent_id) if parent_id.present?

        if @node.update(attributes)
          redirect_to brand_admin_node_path(@brand.slug, @node), notice: "Nodo aggiornato."
        else
          @processes = @node.brand_processes.order(:title)
          load_form_options
          flash.now[:alert] = @node.errors.full_messages.to_sentence
          render :show, status: :unprocessable_entity
        end
      end

      def destroy
        if @node == @brand
          redirect_to brand_admin_node_path(@brand.slug, @node), alert: "Il nodo radice del Brand non può essere eliminato da questa vista."
        elsif @node.children.exists?
          redirect_to brand_admin_node_path(@brand.slug, @node), alert: "Prima di eliminare il nodo, ricolloca o elimina i nodi figli."
        elsif @node.destroy
          redirect_to brand_admin_nodes_path(@brand.slug), notice: "Nodo eliminato."
        else
          redirect_to brand_admin_node_path(@brand.slug, @node), alert: @node.errors.full_messages.to_sentence
        end
      end

      private

        def set_brand
          @brand = Node.includes(:domains, :role_assignment).find_by!(slug: params[:brand_slug])
          raise ActiveRecord::RecordNotFound, "Brand non trovato" unless @brand.brand?
        end

        def set_node
          @node = @brand.self_and_descendants.find(params[:id])
        end

        def node_params
          params.require(:node).permit(:title, :description, :parent_id, :status, :link_node_id)
        end

        def load_form_options
          excluded_ids = @node ? @node.self_and_descendants.select(:id) : []
          @parent_options = @brand.self_and_descendants.where.not(id: excluded_ids).order(:title)
          @link_node_options = Node.where(role_assignment: @brand.role_assignment).where.not(id: @node&.id).order(:title)
        end
    end
  end
end
