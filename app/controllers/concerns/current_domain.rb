module CurrentDomain
  extend ActiveSupport::Concern

  included do
    helper_method :current_domain, :current_node, :current_domain_host, :dedicated_domain_host, :local_request?
  end

  private
    def current_domain
      if local_request? && local_domain_slug.present?
        return Current.domain = local_route_domain
      end
      if local_request? && local_route_domain.present?
        Current.domain ||= local_route_domain
      end
      if local_request? && session[:override_domain_id].present?
        Current.domain ||= Domain.find_by(id: session[:override_domain_id])
      end
      Current.domain ||= Domain.active.find_by(hostname: current_domain_host)
      Current.domain ||= Domain.find_for_host(current_domain_host)
    end

    def current_node
      current_domain&.node
    end

    def local_request?
      request.host == "localhost" || request.host == "127.0.0.1" || request.host == "::1"
    end

    def local_route_domain
      return @local_route_domain if defined?(@local_route_domain)

      slug = local_domain_slug || request.path.split("/")[1]
      @local_route_domain = domain_for_local_slug(slug)
    end

    def local_domain_slug
      path = request.path_parameters
      path[:admin_brand_slug].presence || path[:brand_slug].presence || path[:path_slug].presence || params[:site].presence
    end

    def domain_for_local_slug(slug)
      return if slug.blank?

      normalized = slug.to_s.strip.downcase
      candidates = [normalized, normalized.delete("-")].uniq
      domain = Domain.active.includes(:node).order(primary: :desc, id: :asc).find do |record|
        [record.auth_slug, record.site_key, record.node&.slug].compact.any? { |value| candidates.include?(value) }
      end
      domain&.canonical_domain_record
    end

    def current_domain_host
      Domain.normalize_host(dedicated_domain_host)
    end

    def dedicated_domain_host
      configured_host = ENV["DEDICATED_DOMAIN_HOST_OVERRIDE"].presence
      return configured_host if configured_host.present?

      forwarded_host = request.headers["X-Forwarded-Host"].to_s.split(",").first.presence
      forwarded_host || request.host
    end
end
