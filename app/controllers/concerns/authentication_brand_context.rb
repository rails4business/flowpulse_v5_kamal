module AuthenticationBrandContext
  extend ActiveSupport::Concern

  included do
    helper_method :authentication_context_domain,
      :authentication_context_site,
      :authentication_context?,
      :authentication_context_link_params,
      :authentication_context_default_return_to
  end

  private

    # The host is authoritative in production. The public site key is accepted
    # only on localhost, where several brands share the same host.
    def authentication_context_domain
      return @authentication_context_domain if defined?(@authentication_context_domain)

      domain = current_domain
      domain = local_authentication_domain if domain.blank? || !authentication_enabled?(domain)
      domain = session_authentication_domain if domain.blank?
      @authentication_context_domain = authentication_enabled?(domain) ? domain : nil
    end

    def authentication_context_site
      authentication_context_domain&.auth_slug
    end

    def authentication_context?
      authentication_context_domain.present?
    end

    def authentication_context_default_return_to
      authentication_context_domain&.auth_default_path.presence || root_path
    end

    def authentication_context_link_params(return_to: nil)
      params = {}
      params[:site] = authentication_context_site if local_request? && authentication_context_site.present?
      safe_return_to = safe_authentication_return_to(return_to)
      params[:return_to] = safe_return_to if safe_return_to.present?
      params
    end

    def persist_authentication_return_to!(value = params[:return_to])
      safe_return_to = safe_authentication_return_to(value)
      if safe_return_to.present?
        session[:return_to_after_authenticating] = safe_return_to
      elsif value.present?
        session.delete(:return_to_after_authenticating)
      end
    end

    def safe_authentication_return_to(value)
      candidate = value.to_s.strip
      return if candidate.blank?
      return unless candidate.start_with?("/")
      return if candidate.start_with?("//") || candidate.include?("\\") || candidate.match?(/[\r\n\0]/)

      if authentication_context?
        prefix = authentication_context_path_prefix
        return unless prefix.present? && (candidate == prefix || candidate.start_with?("#{prefix}/"))
      end

      candidate
    end

    def persist_authentication_context!
      if authentication_context?
        session[:authentication_site] = authentication_context_site
      elsif local_request? && params[:site].present?
        session.delete(:authentication_site)
      end
    end

    def clear_authentication_context!
      session.delete(:authentication_site)
    end

    def redirect_authenticated_user_from_authentication!
      return unless authenticated?

      destination = authentication_context? ? authentication_context_default_return_to : profile_path
      redirect_to destination, notice: "Hai già effettuato l’accesso."
    end

    def authentication_enabled?(domain)
      return false if domain.blank?

      ActiveModel::Type::Boolean.new.cast(domain.auth_enabled)
    end

    def local_authentication_domain
      return unless local_request?

      site = params[:site].to_s.strip.downcase.presence
      site ||= "posturacorretta" if request.path.start_with?("/posturacorretta")
      return if site.blank?

      Domain.active.to_a.find { |domain| domain.auth_slug == site }
    end

    def session_authentication_domain
      site = session[:authentication_site].to_s.presence
      return if site.blank?

      Domain.active.to_a.find { |domain| domain.auth_slug == site }
    end

    def authentication_context_path_prefix
      path = authentication_context_domain&.auth_default_path.to_s
      return if path.blank? || !path.start_with?("/")

      "/#{path.split("/")[1]}"
    end
end
