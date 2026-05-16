# app/helpers/dedicated_domains_helper.rb
module DedicatedDomainsHelper
  def current_dedicated_host
    if Rails.env.development?
      ENV.fetch("DEDICATED_DOMAIN_HOST_OVERRIDE", request.host)
    else
      request.host
    end
  end

  def flowpulse_domain?
    current_dedicated_host.in?(
      ["flowpulse.net", "www.flowpulse.net", "localhost"]
    )
  end
end