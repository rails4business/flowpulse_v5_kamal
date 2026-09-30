module Brands
  module Admin
    class NodesController < BaseController
      before_action :set_node, only: %i[show update destroy lifecycle]

      def index
        @active_view = params[:view] == "schema" ? "schema" : "list"
        @nodes = @brand.self_and_descendants
          .includes(:node_processes, :link_node, :node_events)
          .order(:position, :title, :id)
          .to_a
        @nodes_by_parent_id = @nodes.group_by(&:parent_id)
        load_form_options
      end

      def show
        @processes = @node.node_processes.order(:title)
        @brand_development_entries = FlowpulseDevelopmentRepository.new.entries.select { |entry| entry.fetch("owner_brand") == @brand.slug }
        @development_entries = @brand_development_entries.select { |entry| entry["node_slug"] == @node.slug }
        @development_entries_by_slug = @brand_development_entries.index_by { |entry| entry.fetch("slug") }
        load_form_options
      end

      def create
        parent = brand_nodes.find(node_params.delete(:parent_id).presence || @brand.id)
        node = Node.new(node_params.merge(parent: parent, role_assignment: @brand.role_assignment, node_type: :project))

        if node.save
          node.node_events.create!(kind: "created", performed_by_user: Current.user)
          redirect_to brand_admin_node_path(@brand.slug, node), notice: "Nodo creato."
        else
          redirect_to brand_admin_nodes_path(@brand.slug), alert: node.errors.full_messages.to_sentence
        end
      end

      def update
        attributes = node_params
        parent_id = attributes.delete(:parent_id)
        @node.parent = brand_nodes.where.not(id: @node.self_and_descendants.map(&:id)).find(parent_id) if parent_id.present?

        if @node.update(attributes)
          redirect_to brand_admin_node_path(@brand.slug, @node), notice: "Nodo aggiornato."
        else
          @processes = @node.node_processes.order(:title)
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

      def lifecycle
        kind = params[:event].to_s
        unless NodeEvent::KINDS.excluding("created").include?(kind)
          return redirect_to brand_admin_node_path(@brand.slug, @node), alert: "Passaggio di stato non valido."
        end

        event = @node.node_events.new(node_event_params.merge(kind:, performed_by_user: Current.user))
        unless event.save
          return redirect_to brand_admin_node_path(@brand.slug, @node), alert: event.errors.full_messages.to_sentence
        end
        redirect_to brand_admin_node_path(@brand.slug, @node), notice: "Stato operativo aggiornato."
      end

      def create_process
        @node = brand_nodes.find(params[:id])
        process_record = @node.node_processes.new(process_params.merge(created_by_user: Current.user))
        if process_record.save
          redirect_to brand_admin_node_path(@brand.slug, @node, anchor: "node-processes"), notice: "Processo aggiunto."
        else
          redirect_to brand_admin_node_path(@brand.slug, @node, anchor: "node-processes"), alert: process_record.errors.full_messages.to_sentence
        end
      end

      private

        def set_node
          @node = brand_nodes.find(params[:id])
        end

        def brand_nodes
          Node.where(id: @brand.self_and_descendants.map(&:id))
        end

        def node_params
          params.require(:node).permit(:title, :description, :parent_id, :status, :link_node_id)
        end

        def node_event_params
          params.fetch(:node_event, {}).permit(:title, :note, :body_md, :development_entry_slug)
        end

        def process_params
          params.require(:node_process).permit(:title, :slug, :description, :status)
        end

        def load_form_options
          excluded_ids = @node ? @node.self_and_descendants.select(:id) : []
          @parent_options = @brand.self_and_descendants.where.not(id: excluded_ids).order(:title)
          @link_node_options = Node.where(role_assignment: @brand.role_assignment).where.not(id: @node&.id).order(:title)
        end
    end
  end
end
