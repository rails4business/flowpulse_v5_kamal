class UsersController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: %i[ new create ]

  def new
    session[:return_to_after_authenticating] = params[:return_to] if params[:return_to].present?
    @user = User.new
    @user.build_profile
    @subscription_domain = pending_subscription_domain
  end

  def create
    @user = User.new(user_params)
    @user.build_profile

    if @user.save
      start_new_session_for @user
      domain = pending_subscription_domain
      subscribe_current_user_to_domain(domain) if domain.present?
      notice = domain.present? ? "Registrazione completata. Ti sei iscritto gratuitamente a #{domain.display_hostname}." : "Registrazione completata."
      redirect_to after_authentication_url, notice: notice
    else
      @subscription_domain = pending_subscription_domain
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end

    def pending_subscription_domain
      domain_id = params[:subscription_domain_id].presence || params.dig(:user, :subscription_domain_id).presence
      return nil if domain_id.blank?

      Domain.active.find_by(id: domain_id)
    end
end
