module Brands
  class PercorsoIntegratoController < ApplicationController
    layout "landing"
    allow_unauthenticated_access

    def index
      load_site
    end

    def docs
      load_site
      data = YAML.safe_load_file(docs_index_path, permitted_classes: [], aliases: false) || {}
      @docs_sections = visible_docs_sections(data.fetch("sections", []))
      @current_doc = @docs_sections.flat_map { |section| section.fetch("items", []) }
        .find { |item| item.fetch("slug") == params[:doc] }
      @current_doc ||= @docs_sections.first&.fetch("items", [])&.first
      @doc_component = docs_component(@current_doc)
      @doc_markdown = @doc_component ? "" : load_doc_markdown(@current_doc)
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

    def docs_root
      Rails.root.join("config/data/brands/percorso-integrato/docs").cleanpath
    end

    def docs_index_path
      docs_root.join("indice.yml")
    end

    def load_doc_markdown(doc)
      return "" unless doc

      path = docs_root.join(doc.fetch("source")).cleanpath
      return "" unless path.to_s.start_with?("#{docs_root}/") && path.extname == ".md" && path.file?

      path.read
    end

    def visible_docs_sections(sections)
      is_tutor = Current.user&.superadmin_user? || Current.user&.role_assignments&.where(role: :operator, role_operator: "tutor")&.exists?
      sections.reject { |section| section["visibility"] == "internal_tutor" && !is_tutor }
    end

    def docs_component(doc)
      return unless doc&.fetch("type", "markdown") == "component"

      component = doc["component"].to_s
      return unless component.in?(%w[inizia scegli_programma linee_guida orientamento professionisti prossimo_passo])

      "brands/percorso_integrato/docs/components/#{component}"
    end
  end
end
