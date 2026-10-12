class SitemapsController < ApplicationController
  allow_unauthenticated_access
  layout false

  def show
    domain = current_domain
    if domain.blank? || domain.canonical_host.present?
      return head :not_found
    end

    unless PublicDiscovery::AccessPolicy.new.public_domain?(domain)
      response.set_header("X-Robots-Tag", "noindex, nofollow")
      return head :not_found
    end

    @urls = PublicDiscovery::DomainUrls.new(domain).call

    respond_to do |format|
      format.xml
    end
  end

end
