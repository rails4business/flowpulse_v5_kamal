class DomainsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_domain

  def show
    I18n.with_locale(Current.domain&.locale || I18n.default_locale) do
      if Current.domain&.canonical_host.present? && request.host != Current.domain.canonical_host
        return redirect_to_canonical_host
      end

      dispatch_domain_action
    end
  end

  private
    def set_domain
      Current.domain = Domain.find_for_host(dedicated_domain_host)
    end

    def redirect_to_canonical_host
      canonical_host = Current.domain&.canonical_host.to_s.strip
      return if canonical_host.blank?
      return if request.host == canonical_host

      redirect_to(
        "#{request.protocol}#{canonical_host}#{request.fullpath}",
        status: :moved_permanently,
        allow_other_host: true
      )
    end

    def dispatch_domain_action
      if Current.domain&.target_controller.present?
        render "#{Current.domain.target_controller}/#{Current.domain.target_action}"
      else
        render "pages/flowpulse"
      end
    end

    
end
