class LlmsController < ApplicationController
  allow_unauthenticated_access
  layout false

  def show
    requested_domain = Domain.active.find_by(hostname: current_domain_host)
    if requested_domain&.canonical_host.present? && !local_request?
      return redirect_to "https://#{requested_domain.canonical_host}/llms.txt", status: :moved_permanently, allow_other_host: true
    end

    domain = current_domain
    return head(:not_found) if domain.blank?

    unless local_request? || current_domain_host == domain.hostname
      return redirect_to "https://#{domain.hostname}/llms.txt", status: :moved_permanently, allow_other_host: true
    end

    projection = PublicDiscovery::Projection.new(domain).call
    unless domain.llms_discovery_enabled? && projection.present?
      response.set_header("X-Robots-Tag", "noindex, nofollow")
      return head :not_found
    end

    document = PublicDiscovery::LlmsDocument.new(domain, projection:).call
    expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour
    render plain: document, content_type: "text/plain" if stale?(etag: document, public: true)
  end
end
