class DedicatedDomainsController < ApplicationController
  layout "dedicated_domain"

  allow_unauthenticated_access
  before_action :set_dedicated_domain

  def show
    I18n.with_locale(Current.dedicated_domain&.locale || I18n.default_locale) do
      return redirect_to_canonical_host if Current.dedicated_domain&.canonical_host

      case Current.dedicated_domain&.action
      when "markpostura"
        markpostura
      else
        mvp_home
      end
    end
  end

  private
    def markpostura
      render "pages/markpostura"
    end

    def mvp_home
      render "pages/mvp_home"
    end

    def set_dedicated_domain
      Rails.logger.info "REQUEST HOST: #{request.host}"
      Rails.logger.info "OVERRIDE: #{ENV['DEDICATED_DOMAIN_HOST_OVERRIDE']}"
      Rails.logger.info "DEDICATED DOMAIN HOST: #{dedicated_domain_host}"

      Current.dedicated_domain = DedicatedDomain.find(dedicated_domain_host)

      Rails.logger.info "DEDICATED DOMAIN: #{Current.dedicated_domain.inspect}"
      Rails.logger.info "ACTION: #{Current.dedicated_domain&.action}"
    end

    def redirect_to_canonical_host
      redirect_to "#{request.protocol}#{Current.dedicated_domain.canonical_host}#{request.fullpath}", status: :moved_permanently
    end
end
