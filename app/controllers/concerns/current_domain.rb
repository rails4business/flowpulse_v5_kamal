module CurrentDomain
  extend ActiveSupport::Concern

  included do
    helper_method :current_domain, :current_domain_host, :dedicated_domain_host
  end

  private
    def current_domain
      Current.domain ||= Domain.find_for_host(current_domain_host)
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
