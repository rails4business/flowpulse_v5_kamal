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

      @services = Array(@professional["services"]) + load_connections("servizi.yml", "paths").select { |item| item["professional_slug"] == params[:slug] }
      @contents = load_connections("contenuti.yml", "content_connections").select { |item| item["professional_slug"] == params[:slug] }
      @profile_tab = params[:tab].presence_in(%w[profilo servizi formazione contenuti]) || "profilo"
    end

    def professional_material
      load_professional_material
      @material_context = :percorso_integrato
      render "brands/genera_impresa/material"
    end

    def professional_exercise
      load_professional_material
      @exercise = find_professional_exercise
      @material_context = :percorso_integrato
      render "brands/genera_impresa/exercise"
    end

    def professional_material_image
      load_professional_material
      image = find_professional_exercise
      path = Rails.root.join(@material.fetch("source_directory"), "images", image.fetch("image"))
      raise ActiveRecord::RecordNotFound, "Immagine non trovata" unless path.file?

      send_file path, type: "image/gif", disposition: "inline"
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
      people = PersonProfileCatalog.all
      data.fetch("professionals", []).select { |professional| professional["public"] }.map do |professional|
        person = people[professional.fetch("person_profile_slug", professional.fetch("slug"))] || {}
        person.merge(professional).merge(
          "image_url" => professional["image_url"].presence || person["image_url"],
          "video" => professional["video"].presence || person["video"],
          "certifications" => professional["certifications"].presence || person.fetch("certifications", [])
        )
      end
    end

    def load_connections(filename, collection)
      path = Rails.root.join("config/data/posturacorretta/collegamenti", filename)
      return [] unless path.file?

      (YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}).fetch(collection, [])
    end

    def load_professional_material
      load_site
      @professional = public_professionals.find { |person| person.fetch("slug") == params[:slug] }
      raise ActiveRecord::RecordNotFound, "Professionista non trovato" unless @professional

      source_slug = @professional["material_source_brand_slug"]
      source_brand = GeneraImpresaCatalog.load.brand(source_slug) if source_slug.present?
      @material = source_brand&.fetch("materials", [])&.find { |item| item["slug"] == params[:material] }
      raise ActiveRecord::RecordNotFound, "Scheda non trovata" unless @material

      @brand = { "slug" => @professional.fetch("slug"), "name" => @professional.fetch("name") }
    end

    def find_professional_exercise
      exercise = @material.fetch("exercises", []).find { |item| item["position"].to_s == params[:position].to_s }
      raise ActiveRecord::RecordNotFound, "Esercizio non trovato" unless exercise

      exercise
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
