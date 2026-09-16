module Admin
  class EditorialSitesController < BaseController
    before_action :require_superadmin!

    def show
      repository = Editorial::SiteRepository.new
      repository.load(params[:site_key])
      validation = Editorial::Validator.new(repository: repository).validate(params[:site_key])
      raise Editorial::InvalidSourceError, validation.errors.join("; ") unless validation.valid?

      render_editorial_site(params[:site_key], path: requested_path, preview: true)
    rescue Editorial::SourceNotFoundError, Editorial::InvalidKeyError
      raise ActionController::RoutingError, "Site editoriale non trovato"
    end

    private

    def requested_path
      params[:path].present? ? "/#{params[:path].to_s.delete_prefix('/')}" : "/"
    end
  end
end
