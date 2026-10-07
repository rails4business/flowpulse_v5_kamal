module Brands
  class GeneraImpresaController < ApplicationController
    layout "landing"
    allow_unauthenticated_access
    before_action :load_catalog

    def index
      @managed_brands = managed_brands
    end

    def brand
      @brand = @catalog.brand(params[:slug])
      raise ActiveRecord::RecordNotFound, "Brand non trovato" unless @brand
    end

    def project
      @project = @catalog.project(params[:slug])
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" unless @project

      @brand = @catalog.brand_for_project(@project)
    end

    private

    def load_catalog
      @catalog = GeneraImpresaCatalog.load
      @site = @catalog.site
      @brands = @catalog.brands
    end

    def managed_brands
      return [] unless Current.user

      Node.includes(:domains, :role_assignment)
        .select(&:brand?)
        .select { |node| node.administered_by?(Current.user) }
        .sort_by { |node| node.title.downcase }
    end
  end
end
