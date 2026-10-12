module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      session_id = cookies.signed[:session_id]
      return if session_id.blank?

      authenticated_session = Session.find_by(id: session_id)
      requested_domain = current_domain || authentication_context_domain
      can_enter_brand_access = authenticated_session&.brand_access.nil? && controller_path.in?(%w[sessions users])
      if authenticated_session&.active? && (requested_domain.blank? || authenticated_session.valid_for?(requested_domain) || can_enter_brand_access)
        return authenticated_session
      end

      authenticated_session&.revoke! if authenticated_session&.revoked_at.nil?
      cookies.delete(:session_id)
      nil
    end

    def request_authentication
      persist_authentication_return_to!(request.fullpath)
      redirect_to new_session_path(authentication_context_link_params(return_to: session[:return_to_after_authenticating]))
    end

    def after_authentication_url
      safe_authentication_return_to(session.delete(:return_to_after_authenticating)) || authentication_context_default_return_to
    end

    def start_new_session_for(user, brand_access: nil, authentication_method: "password")
      user.sessions.create!(
        brand_access: brand_access,
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        authentication_method:
      ).tap do |authenticated_session|
        Current.session = authenticated_session
        cookies.signed.permanent[:session_id] = {
          value: authenticated_session.id,
          httponly: true,
          same_site: :lax,
          secure: Rails.env.production?,
          expires: authenticated_session.expires_at
        }
      end
    end

    def terminate_session
      Current.session&.revoke!
      Current.session = nil
      cookies.delete(:session_id)
    end
end
