module Brands
  module Admin
    class PrivacyController < BaseController
      def index
        @privacy_domains = @brand.domains.order(:hostname).map do |domain|
          { domain: domain, config: PrivacyCatalog.for(host: domain.hostname) }
        end
      end
    end
  end
end
