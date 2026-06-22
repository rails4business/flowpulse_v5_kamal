class SessionsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    session[:return_to_after_authenticating] = params[:return_to] if params[:return_to].present?
    @subscription_domain = pending_subscription_domain
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      domain = pending_subscription_domain
      subscribe_current_user_to_domain(domain) if domain.present?
      notice = domain.present? ? "Ti sei iscritto gratuitamente a #{domain.display_hostname}." : nil
      redirect_to after_authentication_url, notice: notice
    else
      redirect_to new_session_path(subscription_domain_id: params[:subscription_domain_id]), alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def pending_subscription_domain
    domain_id = params[:subscription_domain_id].presence
    return nil if domain_id.blank?

    Domain.active.find_by(id: domain_id)
  end
end
