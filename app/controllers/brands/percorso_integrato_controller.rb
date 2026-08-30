module Brands
  class PercorsoIntegratoController < ApplicationController
    layout "landing"
    allow_unauthenticated_access

    def index
      load_site
    end

    def professionals
      load_site
      @professionals = public_professionals
    end

    def professional
      load_site
      @professional = public_professionals.find { |person| person.fetch("slug") == params[:slug] }
      return redirect_to(percorso_integrato_professionals_path, alert: "Professionista non trovato") unless @professional

      @services = load_connections("servizi.yml", "paths").select { |item| item["professional_slug"] == params[:slug] }
      @contents = load_connections("contenuti.yml", "content_connections").select { |item| item["professional_slug"] == params[:slug] }
    end

    def places
      load_site
      data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/accademia/centers.yml"), permitted_classes: [], aliases: false) || {}
      @places = data.fetch("centers", {}).values.select { |place| Array(place["projects"]).include?("percorso-integrato") }
    end

    private

    def load_site
      data = PercorsoIntegratoCatalog.load
      @site = data.fetch("site")
      @principles = data.fetch("principles", [])
      @roles = data.fetch("roles", [])
      @steps = data.fetch("steps", [])
    end

    def public_professionals
      data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/posturacorretta_professionisti.yml"), permitted_classes: [], aliases: false) || {}
      data.fetch("professionals", []).select { |professional| professional["public"] }
    end

    def load_connections(filename, collection)
      path = Rails.root.join("config/data/posturacorretta/collegamenti", filename)
      return [] unless path.file?

      (YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}).fetch(collection, [])
    end
  end
end
