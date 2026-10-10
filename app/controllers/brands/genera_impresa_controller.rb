module Brands
  class GeneraImpresaController < ApplicationController
    layout "landing"
    allow_unauthenticated_access
    before_action :load_catalog

    def index
      @managed_brands = managed_brands
      @personal_brands = @brands.select { |brand| personal_brand?(brand) }
      @project_brands = @brands.reject { |brand| personal_brand?(brand) }
    end

    def brand
      requested_brand = @catalog.brand(params[:slug])
      if requested_brand&.dig("professional_profile_slug").present?
        profile_path = percorso_integrato_professional_path(requested_brand.fetch("professional_profile_slug"))
        destination = local_request? ? profile_path : "https://percorsointegrato.it#{profile_path}"
        return redirect_to destination, status: :moved_permanently, allow_other_host: true
      end

      load_brand
      render @brand.fetch("page_template") if @brand["page_template"].present?
    end

    def material
      load_brand
      @material = find_material
    end

    def exercise
      load_brand
      @material = find_material
      @exercise = find_exercise(@material)
    end

    def material_image
      load_brand
      material = find_material
      image = find_exercise(material)

      path = Rails.root.join(material.fetch("source_directory"), "images", image.fetch("image"))
      raise ActiveRecord::RecordNotFound, "Immagine non trovata" unless path.file?

      send_file path, type: "image/gif", disposition: "inline"
    end

    def project
      @project = @catalog.project(params[:slug])
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" unless @project
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" if @project["visibility"] == "private" && !superadmin_catalog_access?

      @brand = @catalog.brand_for_project(@project)
      render @project["view"] if @project["view"].present?
    end

    def project_step
      @project = @catalog.project(params[:slug])
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" unless @project
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" if @project["visibility"] == "private" && !superadmin_catalog_access?

      @step = @project.fetch("steps", []).find { |step| step.is_a?(Hash) && step["slug"] == params[:step] }
      raise ActiveRecord::RecordNotFound, "Passaggio non trovato" unless @step

      @step_index = @project.fetch("steps").index(@step)
      @previous_step = @project.fetch("steps")[@step_index - 1] if @step_index.positive?
      @next_step = @project.fetch("steps")[@step_index + 1]
    end

    private

    def load_catalog
      @catalog = GeneraImpresaCatalog.load
      @site = @catalog.site
      @brands = @catalog.brands.select do |brand|
        brand.fetch("catalog_visible", true) && (brand_public?(brand) || superadmin_catalog_access?)
      end
    end

    def managed_brands
      return [] unless Current.user

      Node.includes(:domains, :role_assignment)
        .select(&:brand?)
        .select { |node| node.administered_by?(Current.user) }
        .sort_by { |node| node.title.downcase }
    end

    def load_brand
      @brand = @catalog.brand(params[:slug])
      raise ActiveRecord::RecordNotFound, "Brand non trovato" unless @brand
      raise ActiveRecord::RecordNotFound, "Brand non trovato" unless brand_public?(@brand) || superadmin_catalog_access?
    end

    def brand_public?(brand)
      brand["status"] == "launched" || brand["visibility"] == "public"
    end

    def personal_brand?(brand)
      brand["brand_type"] == "personal" || brand["kind"] == "professional"
    end

    def superadmin_catalog_access?
      Current.user&.superadmin_user?
    end

    def find_material
      material = @brand.fetch("materials", []).find { |item| item["slug"] == params[:material] }
      raise ActiveRecord::RecordNotFound, "Materiale non trovato" unless material

      material
    end

    def find_exercise(material)
      exercise = material.fetch("exercises", []).find { |item| item["position"].to_s == params[:position].to_s }
      raise ActiveRecord::RecordNotFound, "Esercizio non trovato" unless exercise

      exercise
    end
  end
end
