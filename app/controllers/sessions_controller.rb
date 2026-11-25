class SessionsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_authenticated_user_from_authentication!, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    persist_authentication_context!
    persist_authentication_return_to!
    remember_pending_invitation!
    @subscription_domain = pending_subscription_domain
    @brand_invitation = pending_invitation
  end

  def create
    persist_authentication_context!
    persist_authentication_return_to!
    remember_pending_invitation!
    invitation = pending_invitation
    requested_domain = invitation&.source_domain || pending_subscription_domain || authentication_context_domain

    if requested_domain&.resolved_node&.slug == "flowpulse"
      authenticate_superadmin!
    elsif requested_domain&.resolved_node
      authenticate_brand!(requested_domain, invitation)
    else
      authenticate_platform_or_legacy_user!
    end
  end

  def destroy
    terminate_session
    clear_authentication_context!
    redirect_to new_session_path, status: :see_other
  end

  private

  def authenticate_brand!(domain, invitation)
    credential = BrandCredential.active.find_by(
      brand_node: domain.resolved_node,
      email_address: params[:email_address].to_s.strip.downcase
    )
    unless credential&.authenticate(params[:password])
      return if authenticate_superadmin_from_brand!

      redirect_to new_session_path(authentication_context_link_params(return_to: session[:return_to_after_authenticating])),
        alert: "Email o password non valide per questo Brand."
      return
    end

    user = credential.brand_access.profile.user
    unless user.active_registration?
      redirect_to new_session_path(authentication_context_link_params),
        alert: "Questo account è sospeso. Contatta l’amministrazione per verificare l’accesso."
      return
    end
    if invitation.present? && !invitation.email_address.casecmp?(credential.email_address)
      redirect_to new_session_path(authentication_context_link_params), alert: "L’invito appartiene a un altro indirizzo email."
      return
    end

    User.transaction do
      if invitation&.pending?
        invitation.accept!(user)
        complete_access_request_for!(invitation)
      end
      credential.record_authentication!
    end
    start_new_session_for(
      user,
      brand_access: credential.brand_access,
      brand_credential: credential,
      authentication_method: "brand_password"
    )
    session.delete(:pending_brand_invitation_token)
    redirect_to after_authentication_url, notice: "Benvenuto in #{domain.site_title.presence || domain.display_hostname}."
  rescue ActiveRecord::RecordInvalid
    redirect_to new_session_path(authentication_context_link_params), alert: "Non è stato possibile completare l’accesso al Brand."
  end

  def authenticate_superadmin!
    return if authenticate_platform_credential!
    return if authenticate_legacy_superadmin!

    redirect_to new_session_path, alert: "Email o password non valide."
  end

  def authenticate_superadmin_from_brand!
    authenticate_platform_credential! || authenticate_legacy_superadmin!
  end

  def authenticate_platform_credential!
    credential = PlatformCredential.active.find_by(
      email_address: params[:email_address].to_s.strip.downcase
    )
    return false unless credential&.authenticate(params[:password])

    profile = credential.profile
    return false unless profile.system_role_assignments.currently_effective.superadmin.exists?

    user = profile.user
    return false unless user.active_registration?

    credential.record_authentication!
    start_new_session_for(
      user,
      profile:,
      platform_credential: credential,
      authentication_method: "platform_credential"
    )
    redirect_to after_authentication_url, notice: "Accesso superadmin effettuato."
    true
  end

  def authenticate_legacy_superadmin!
    user = User.authenticate_by(params.permit(:email_address, :password))
    return false unless user&.legacy_superadmin? && user.active_registration?

    start_new_session_for(user, authentication_method: "legacy_platform_password")
    redirect_to after_authentication_url, notice: "Accesso superadmin effettuato."
    true
  end

  def authenticate_platform_or_legacy_user!
    return if authenticate_platform_credential!

    user = User.authenticate_by(params.permit(:email_address, :password))
    unless user&.active_registration?
      redirect_to new_session_path, alert: "Email o password non valide."
      return
    end

    authentication_method = user.superadmin_user? ? "platform_password" : "legacy_user_password"
    start_new_session_for(user, authentication_method:)
    notice = user.superadmin_user? ? "Accesso superadmin effettuato." : "Accesso effettuato."
    redirect_to after_authentication_url, notice: notice
  end

  def pending_subscription_domain
    subscription_token = params[:subscription].presence
    return nil if subscription_token.blank?

    Domain.find_signed(subscription_token, purpose: :free_subscription)&.then do |domain|
      domain if domain.active? && domain.node_id.present?
    end
  end


  def remember_pending_invitation!
    token = params[:invitation].presence
    session[:pending_brand_invitation_token] = token if BrandInvitation.find_pending_by_token(token)
  end

  def pending_invitation
    BrandInvitation.find_pending_by_token(session[:pending_brand_invitation_token])
  end
end
