class SessionsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_authenticated_user_from_authentication!, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    persist_authentication_context!
    persist_authentication_return_to!
    @subscription_domain = pending_subscription_domain
  end

  def create
    persist_authentication_context!
    persist_authentication_return_to!
    if user = User.authenticate_by(params.permit(:email_address, :password))
      begin
        brand_domain = authentication_context_domain
        domain = pending_subscription_domain
        User.transaction do
          profile = user.profile || user.create_profile!(display_name: user.email_address.to_s.split("@").first)
          ensure_profile_site_access!(profile, brand_domain) if brand_domain.present?
          subscribe_profile_to_domain(profile, domain) if domain.present?
        end
        start_new_session_for user
        notice = if brand_domain.present?
          "Benvenuto in #{brand_domain.site_title}."
        elsif domain.present?
          "Ti sei iscritto gratuitamente a #{domain.display_hostname}."
        end
        redirect_to after_authentication_url, notice: notice
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

    Domain.find_signed(subscription_token, purpose: :free_subscription)&.then { |domain| domain if domain.active? }
  end
end
