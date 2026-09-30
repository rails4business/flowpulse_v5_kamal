module Brands
  module Admin
    class DevelopmentController < BaseController

      def index
        @development_entries = repository.entries.select { |entry| entry.fetch("owner_brand") == @brand.slug }
      end

      def show
        @development_entry = repository.find(params[:slug])
        unless @development_entry&.fetch("owner_brand") == @brand.slug
          raise ActiveRecord::RecordNotFound, "Scheda di sviluppo non trovata per questo Brand"
        end
        @development_node = @brand.self_and_descendants.find_by(slug: @development_entry["node_slug"]) if @development_entry["node_slug"].present?
      end

      private

        def repository
          @repository ||= FlowpulseDevelopmentRepository.new
        end
    end
  end
end
