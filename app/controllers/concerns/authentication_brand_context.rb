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

      domain = current_domain&.canonical_domain_record
      domain = local_authentication_domain if domain.blank? || !authentication_enabled?(domain)
      domain = pending_invitation_authentication_domain if domain.blank?
      domain = session_authentication_domain if domain.blank?
      domain = domain&.canonical_domain_record
      @authentication_context_domain = authentication_enabled?(domain) ? domain : nil
    end

    def authentication_context_site
      domain = authentication_context_domain
      domain&.auth_slug.presence || domain&.site_key.presence || domain&.node&.slug
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

      if authentication_context?
        invitation = BrandInvitation.find_pending_by_token(session[:pending_brand_invitation_token])
        profile = Current.user.profile
        unless invitation_or_administration_allows_access?(profile, authentication_context_domain, invitation)
          redirect_to new_brand_access_request_path(authentication_context_link_params),
            alert: "Non hai ancora accesso a questo Brand. Puoi richiedere un invito al suo responsabile."
          return
        end
        access = grant_current_user_brand_access!(authentication_context_domain)
        if invitation&.email_address&.casecmp?(Current.user.email_address)
          invitation.accept!(Current.user)
          complete_access_request_for!(invitation)
          session.delete(:pending_brand_invitation_token)
        end
        Current.session.update!(brand_access: access) if access.present? && Current.session.brand_access_id != access.id
      end

      destination = authentication_context? ? authentication_context_default_return_to : profile_path
      redirect_to destination, notice: "Hai già effettuato l’accesso."
    end

    def authentication_enabled?(domain)
      return false if domain.blank?
      return false unless domain.active? && domain.node_id.present?
      return true if domain.auth_enabled.nil?

      ActiveModel::Type::Boolean.new.cast(domain.auth_enabled)
    end

    def local_authentication_domain
      return unless local_request?

      site = params[:site].to_s.strip.downcase.presence
      site ||= "posturacorretta" if request.path.start_with?("/posturacorretta")
      site ||= "corpoecoscienza" if request.path.start_with?("/corpo-e-coscienza")
      return if site.blank?

      Domain.active.includes(:node).to_a.find do |domain|
        [domain.auth_slug, domain.site_key, domain.node&.slug].compact.include?(site)
      end
    end

    def session_authentication_domain
      site = session[:authentication_site].to_s.presence
      return if site.blank?

      Domain.active.includes(:node).to_a.find do |domain|
        [domain.auth_slug, domain.site_key, domain.node&.slug].compact.include?(site)
      end
    end

    def pending_invitation_authentication_domain
      token = session[:pending_brand_invitation_token].to_s.presence
      BrandInvitation.find_pending_by_token(token)&.source_domain&.canonical_domain_record if token
    end

    def authentication_context_path_prefix
      path = authentication_context_domain&.auth_default_path.to_s
      return if path.blank? || !path.start_with?("/")

      "/#{path.split("/")[1]}"
    end
end
