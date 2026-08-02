class PasswordsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      user.password_reset_requests.pending.first_or_create!(requested_at: Time.current)
    end

    redirect_to(authenticated? ? profile_path : new_session_path, notice: "Se l’account esiste, la richiesta è stata inviata all’amministratore. Riceverai il link di reset manualmente.")
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.update_column(:email_change_authorized_at, Time.current)
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Password aggiornata. Accedi di nuovo: potrai modificare anche l’email nei prossimi 30 minuti."
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
