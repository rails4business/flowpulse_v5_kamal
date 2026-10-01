module Brands
  module Admin
    class NodeEventsController < BaseController
      before_action :set_event

      def show
      end

      def update
        if @event.update(event_params)
          redirect_to brand_admin_node_event_path(@brand.slug, @node, @event.public_id), notice: "Evento aggiornato."
        else
          flash.now[:alert] = @event.errors.full_messages.to_sentence
          render :show, status: :unprocessable_entity
        end
      end

      private

        def set_event
          @node = Node.where(id: @brand.self_and_descendants.map(&:id)).find(params[:node_id])
          @event = @node.node_events.find_by!(public_id: params[:public_id])
          @brand_development_entries = FlowpulseDevelopmentRepository.new.entries.select { |entry| entry.fetch("owner_brand") == @brand.slug }
          @development_entry = @brand_development_entries.find { |entry| entry.fetch("slug") == @event.development_entry_slug }
        end

        def event_params
          params.require(:node_event).permit(:title, :note, :body_md, :development_entry_slug)
        end
    end
  end
end
