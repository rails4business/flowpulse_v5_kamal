class DomainsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access
  before_action :set_domain

  def show
    I18n.with_locale(Current.domain&.locale || I18n.default_locale) do
      if Current.domain&.canonical_host.present? && current_domain_host != Current.domain.canonical_host
        return redirect_to_canonical_host
      end

      dispatch_domain_action
    end
  end

  private
    def set_domain
      Current.domain = current_domain
    end

    def redirect_to_canonical_host
      canonical_host = Current.domain&.canonical_host.to_s.strip
      return if canonical_host.blank?
      return if current_domain_host == canonical_host

      redirect_to(
        "#{request.protocol}#{canonical_host}#{request.fullpath}",
        status: :moved_permanently,
        allow_other_host: true
      )
    end

    def dispatch_domain_action
      if Current.domain&.target_controller.present?
        render_domain_target
      else
        render "landing/flowpulse"
      end
    end

    def render_domain_target
      target_controller = Current.domain.target_controller
      target_action = Current.domain.target_action

      if target_controller == "landing"
        render "landing/#{target_action}"
      else
        render "#{target_controller}/#{target_action}"
      end
    end

    
end
