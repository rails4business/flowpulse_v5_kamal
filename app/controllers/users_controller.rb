class UsersController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_authenticated_user_from_authentication!, only: %i[new create]

  def new
    persist_authentication_context!
    persist_authentication_return_to!
    @user = User.new
    @user.build_profile
    @subscription_domain = pending_subscription_domain
  end

  def create
    persist_authentication_context!
    persist_authentication_return_to!
    @user = User.new(user_params)
    @user.build_profile
    brand_domain = authentication_context_domain
    domain = pending_subscription_domain

    begin
      User.transaction do
        @user.save!
        profile = @user.profile || @user.create_profile!(display_name: @user.email_address.to_s.split("@").first)
        ensure_profile_site_access!(profile, brand_domain) if brand_domain.present?
        subscribe_profile_to_domain(profile, domain) if domain.present?
      end

      start_new_session_for @user
      notice = if brand_domain.present?
        "Registrazione completata. Benvenuto in #{brand_domain.site_title}."
      elsif domain.present?
        "Registrazione completata. Ti sei iscritto gratuitamente a #{domain.display_hostname}."
      else
        "Registrazione completata."
      end
      redirect_to after_authentication_url, notice: notice
    rescue ActiveRecord::RecordInvalid => error
      @user.errors.add(:base, error.record.errors.full_messages.to_sentence) unless error.record == @user
      @subscription_domain = pending_subscription_domain
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end

    def pending_subscription_domain
      subscription_token = params[:subscription].presence || params.dig(:user, :subscription).presence
      return nil if subscription_token.blank?

      Domain.find_signed(subscription_token, purpose: :free_subscription)&.then { |domain| domain if domain.active? }
    end
end
