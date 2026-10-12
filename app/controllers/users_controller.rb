class UsersController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_authenticated_user_from_authentication!, only: %i[new create]

  def new
    persist_authentication_context!
    persist_authentication_return_to!
    remember_pending_invitation!
    @user = User.new
    @user.email_address = pending_invitation.email_address if pending_invitation.present?
    @user.build_profile
    @subscription_domain = pending_subscription_domain
  end

  def create
    persist_authentication_context!
    persist_authentication_return_to!
    remember_pending_invitation!
    @user = User.new(user_params)
    @user.build_profile
    brand_domain = authentication_context_domain
    domain = pending_subscription_domain
    invitation = pending_invitation
    target_domain = invitation&.source_domain || domain || brand_domain
    target_brand_node = invitation&.brand_node || target_domain&.node

    begin
      if invitation.present? && !invitation.email_address.casecmp?(@user.email_address)
        @user.errors.add(:email_address, "deve coincidere con l’indirizzo invitato")
        raise ActiveRecord::RecordInvalid, @user
      end

      verification = nil
      raw_token = nil
      User.transaction do
        @user.registration_status = "pending_email_verification"
        @user.email_verified_at = nil
        @user.save!
        @user.create_profile!(display_name: @user.email_address.to_s.split("@").first) unless @user.profile
        verification, raw_token = EmailVerification.issue!(
          user: @user,
          brand_node: target_brand_node,
          requested_domain: target_domain,
          return_to: safe_authentication_return_to(session[:return_to_after_authenticating]),
          request_ip: request.remote_ip,
          user_agent: request.user_agent,
          metadata: { "brand_invitation_id" => invitation&.id }.compact
        )
      end

      RegistrationMailer.verify_email(verification, raw_token, verification_url_for(verification, raw_token)).deliver_now
      redirect_to email_verification_sent_path(email: @user.email_address),
        notice: "Account creato. Controlla l’email per completare la registrazione."
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

      Domain.find_signed(subscription_token, purpose: :free_subscription)&.then do |domain|
        domain if domain.active? && domain.node_id.present?
      end
    end

    def remember_pending_invitation!
      token = params[:invitation].presence || params.dig(:user, :invitation).presence
      session[:pending_brand_invitation_token] = token if BrandInvitation.find_pending_by_token(token)
    end

    def pending_invitation
      BrandInvitation.find_pending_by_token(session[:pending_brand_invitation_token])
    end

    def verification_url_for(verification, raw_token)
      options = { token: raw_token }
      if local_request?
        options.merge!(host: "localhost", port: request.optional_port, protocol: request.protocol)
        options[:site] = authentication_context_site if authentication_context_site.present?
      elsif verification.requested_domain.present?
        options.merge!(host: verification.requested_domain.hostname, protocol: "https")
      else
        options.merge!(host: request.host, protocol: request.protocol)
      end
      email_verification_url(**options)
    end
end
