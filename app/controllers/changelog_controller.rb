class ChangelogController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :require_preview_superadmin!

  def index
    load_repository
    @changelog_entries = decorate_entries(@changelog_repository)
    @changelog_directory = changelog_directory if @changelog_repository.brand_key == "flowpulse"
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound, "Changelog non trovato"
  end

  def show
    load_repository
    @changelog_entry = @changelog_repository.find(params[:slug], include_internal: include_internal?)
    raise ActiveRecord::RecordNotFound, "Aggiornamento non trovato" unless @changelog_entry
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound, "Aggiornamento non trovato"
  end

  private

    def load_repository
      requested_brand = params[:brand].presence
      requested_brand = nil unless local_request? || Current.user&.superadmin_user?

      @changelog_repository = if requested_brand
        ChangelogRepository.new(brand: requested_brand)
      else
        ChangelogRepository.for_host(current_domain_host)
      end
      @changelog_brand = @changelog_repository.brand.merge(
        "home_url" => brand_home_url(@changelog_repository.brand)
      )
      @changelog_preview = requested_brand.present?
      @changelog_index_path = changelog_index_url_for(@changelog_repository.brand)
      @radioestesia = YAML.safe_load_file(Rails.root.join("config/data/radioestesia/site.yml"), permitted_classes: [], aliases: false) if @changelog_repository.brand_key == "radioestesia"
      @markpostura_site = Editorial::SiteRepository.new.load("markpostura_it").site if @changelog_repository.brand_key == "markpostura"
    end

    def changelog_directory
      ChangelogRepository.catalog.values
        .reject { |brand| brand.fetch("key") == "flowpulse" }
        .reject { |brand| brand.fetch("visibility", "public") == "internal" && !include_internal? }
        .map do |brand|
          brand.merge("url" => changelog_url_for(brand))
        end.sort_by { |brand| brand.fetch("label").downcase }
    end

    def decorate_entries(repository)
      brand = repository.brand
      repository.entries(include_internal: include_internal?).map do |entry|
        entry.merge(
          "brand_key" => brand.fetch("key"),
          "brand_label" => brand.fetch("label"),
          "entry_url" => changelog_entry_url_for(brand, entry)
        )
      end
    end

    def changelog_entry_url_for(brand, entry)
      if preview_brand?(brand)
        return radioestesia_changelog_entry_path(entry.fetch("slug"))
      end
      if posturacorretta_brand_path?(brand)
        return posturacorretta_changelog_entry_path(entry.fetch("slug"))
      end

      if local_request?
        brand_changelog_entry_path(brand.fetch("key"), entry.fetch("slug"))
      elsif brand.fetch("key") == @changelog_repository.brand_key
        changelog_entry_path(entry.fetch("slug"))
      else
        "https://#{brand.fetch("canonical_host")}/changelog/aggiornamenti/#{entry.fetch("slug")}"
      end
    end

    def changelog_url_for(brand)
      return brand.fetch("changelog_preview_path") if brand.fetch("visibility", "public") == "internal" && brand["changelog_preview_path"].present?
      return posturacorretta_changelog_path if local_request? && brand.fetch("key") == "posturacorretta"
      return brand_changelog_path(brand.fetch("key")) if local_request?

      "https://#{brand.fetch("canonical_host")}/changelog"
    end

    def brand_home_url(brand)
      return brand.fetch("preview_path") if preview_brand?(brand)
      return brand.fetch("public_path") if local_request?

      "https://#{brand.fetch("canonical_host")}/"
    end

    def include_internal?
      Current.user&.superadmin_user? || false
    end

    def preview_brand?(brand)
      params[:brand_preview] == "1" && brand.fetch("key") == "radioestesia"
    end

    def changelog_index_url_for(brand)
      return radioestesia_changelog_path if preview_brand?(brand)
      return posturacorretta_changelog_path if posturacorretta_brand_path?(brand)
      return brand_changelog_path(brand.fetch("key")) if @changelog_preview

      changelog_path
    end

    def posturacorretta_brand_path?(brand)
      params[:brand_path] == "posturacorretta" && brand.fetch("key") == "posturacorretta"
    end

    def require_preview_superadmin!
      return unless params[:brand_preview] == "1"
      if Current.user&.superadmin_user?
        response.set_header("X-Robots-Tag", "noindex, nofollow")
        return
      end

      request_authentication unless Current.user
      redirect_to flowpulse_path, alert: "Anteprima riservata al superadmin." if Current.user
    end
end
