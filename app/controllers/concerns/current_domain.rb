module CurrentDomain
  extend ActiveSupport::Concern

  included do
    helper_method :current_domain, :current_node, :current_domain_host, :dedicated_domain_host, :local_request?
  end

  private
    def current_domain
      if local_request? && session[:override_domain_id].present?
        Current.domain ||= Domain.find_by(id: session[:override_domain_id])
      end
      Current.domain ||= Domain.find_for_host(current_domain_host)
    end

    def current_node
      current_domain&.node
    end

    def local_request?
      request.host == "localhost" || request.host == "127.0.0.1" || request.host == "::1"
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
