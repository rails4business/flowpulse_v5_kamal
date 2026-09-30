module Brands
  module Admin
    class DevelopmentController < ::Admin::BaseController
      before_action :require_superadmin!
      before_action :set_brand

      def index
        @development_entries = repository.entries.select { |entry| entry.fetch("owner_brand") == @brand.slug }
      end

      def show
        @development_entry = repository.find(params[:slug])
        unless @development_entry&.fetch("owner_brand") == @brand.slug
          raise ActiveRecord::RecordNotFound, "Scheda di sviluppo non trovata per questo Brand"
        end
      end

      private

        def set_brand
          @brand = Node.includes(:domains).find_by!(slug: params[:brand_slug])
          raise ActiveRecord::RecordNotFound, "Brand non trovato" unless @brand.brand?
        end

        def repository
          @repository ||= FlowpulseDevelopmentRepository.new
        end
    end
  end
end
