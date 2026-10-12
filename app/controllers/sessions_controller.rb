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
    if user = User.authenticate_by(params.permit(:email_address, :password))
      unless user.active_registration?
        redirect_to new_session_path(authentication_context_link_params(return_to: session[:return_to_after_authenticating])),
          alert: "Controlla l’email e completa la verifica prima di accedere."
        return
      end

      begin
        brand_domain = authentication_context_domain
        domain = pending_subscription_domain
        invitation = pending_invitation
        if invitation.present? && !invitation.email_address.casecmp?(user.email_address)
          redirect_to new_session_path(authentication_context_link_params), alert: "L’invito appartiene a un altro indirizzo email."
          return
        end
        domain = invitation.source_domain if invitation&.source_domain.present?
        brand_access = nil
        User.transaction do
          profile = user.profile || user.create_profile!(display_name: user.email_address.to_s.split("@").first)
          brand_access = grant_profile_brand_access!(profile, brand_domain) if brand_domain.present?
          brand_access = grant_profile_brand_access!(profile, domain) if domain.present? && domain != brand_domain
          if invitation.present?
            brand_access = grant_profile_brand_access_for_node!(profile, invitation.brand_node, source_domain: invitation.source_domain)
          end
          invitation&.accept!(user)
        end
        start_new_session_for user, brand_access: brand_access
        notice = if brand_domain.present?
          "Benvenuto in #{brand_domain.site_title}."
        elsif domain.present?
          "Ora hai accesso a #{domain.site_title.presence || domain.display_hostname}."
        end
        redirect_to after_authentication_url, notice: notice
        session.delete(:pending_brand_invitation_token)
      rescue ActiveRecord::RecordInvalid
        redirect_to new_session_path(authentication_context_link_params(return_to: session[:return_to_after_authenticating]).merge(subscription: params[:subscription])), alert: "Non è stato possibile completare l’accesso al sito. Riprova."
      end
    else
      redirect_to new_session_path(authentication_context_link_params(return_to: session[:return_to_after_authenticating]).merge(subscription: params[:subscription])), alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    clear_authentication_context!
    redirect_to new_session_path, status: :see_other
  end

  private

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
