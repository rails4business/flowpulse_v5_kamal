module Brands
  class GeneraImpresaController < ApplicationController
    layout "landing"
    allow_unauthenticated_access
    before_action :load_catalog

    def index; end

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
  end
end
