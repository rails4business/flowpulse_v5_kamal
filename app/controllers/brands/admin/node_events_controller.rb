module Brands
  module Admin
    class NodeEventsController < BaseController
      def show
        @node = Node.where(id: @brand.self_and_descendants.map(&:id)).find(params[:node_id])
        @event = @node.node_events.find_by!(public_id: params[:public_id])
        @development_entry = if @event.development_entry_slug.present?
          FlowpulseDevelopmentRepository.new.find(@event.development_entry_slug)
        end
        @development_entry = nil unless @development_entry&.fetch("owner_brand") == @brand.slug
      end
    end
  end
end
