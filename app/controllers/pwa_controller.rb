class PwaController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection only: :service_worker
  before_action :require_enabled_pwa

  def manifest
    render json: @pwa_config.to_manifest, content_type: "application/manifest+json"
  end

  def service_worker
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Service-Worker-Allowed"] = @pwa_config.service_worker_scope
    render formats: :js, content_type: "text/javascript"
  end

  def offline
    response.headers["Cache-Control"] = "public, max-age=3600"
    render layout: false
  end

  private

  def require_enabled_pwa
    @pwa_config = pwa_site_config
    head :not_found unless @pwa_config
  end
end
