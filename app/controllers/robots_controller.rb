class RobotsController < ApplicationController
  allow_unauthenticated_access
  layout false

  def show
    domain = current_domain
    lines = ["User-agent: *"]

    if domain&.node.present? && !public_domain?(domain)
      lines << "Disallow: /"
      response.set_header("X-Robots-Tag", "noindex, nofollow")
    else
      lines.concat([
        "Disallow: /admin",
        "Disallow: /dashboard",
        "Disallow: /creator_world",
        "Disallow: /profilo",
        "Disallow: /session",
        "Disallow: /impegno/agenda",
        "Disallow: /*?*"
      ])
      lines << "Sitemap: #{canonical_base_url(domain)}/sitemap.xml"
      if domain&.llms_discovery_enabled? && PublicDiscovery::Projection.new(domain).call.present?
        lines << "# Public AI discovery: #{canonical_base_url(domain)}/llms.txt"
      end
    end

    render plain: "#{lines.join("\n")}\n", content_type: "text/plain"
  end

  private
    def public_domain?(domain)
      PublicDiscovery::AccessPolicy.new.public_domain?(domain)
    end

    def canonical_base_url(domain)
      domain.present? ? "https://#{domain.hostname}" : request.base_url
    end
end
