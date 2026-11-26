class UsersController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: %i[ new create ]
  before_action :remember_pending_invitation!, only: %i[new create]
  before_action :require_matching_invitation_context!, only: %i[new create]
  before_action :redirect_authenticated_user_from_authentication!, only: %i[new create]
  before_action :require_registration_invitation!, only: :new

  def new
    persist_authentication_context!
    persist_authentication_return_to!
    @user = User.find_by(email_address: pending_invitation&.email_address) || User.new(email_address: pending_invitation&.email_address)
    @user.build_profile unless @user.profile
    @subscription_domain = pending_subscription_domain
  end

  def create
    persist_authentication_context!
    persist_authentication_return_to!
    submitted = user_params
    invitation = pending_invitation
    @user = User.find_by(email_address: invitation&.email_address) || User.new(email_address: submitted[:email_address])
    @user.build_profile unless @user.profile
    unless invitation&.pending?
      @user.errors.add(:base, "Per creare un account serve un invito personale valido.")
      @subscription_domain = pending_subscription_domain
      return render :new, status: :unprocessable_entity
    end

    target_domain = authentication_context_domain
    target_brand_node = invitation.brand_node

    begin
      if invitation.present? && !invitation.email_address.casecmp?(submitted[:email_address].to_s)
        @user.errors.add(:email_address, "deve coincidere con l’indirizzo invitato")
        raise ActiveRecord::RecordInvalid, @user
      end

      result = BrandInvitations::Acceptance.new(invitation: invitation, domain: target_domain).register!(
        user: @user, password: submitted[:password], password_confirmation: submitted[:password_confirmation]
      )

      start_new_session_for(@user, brand_access: result.brand_access, brand_credential: result.brand_credential,
        authentication_method: "brand_invitation")
      session.delete(:pending_brand_invitation_token)
      redirect_to(safe_authentication_return_to(session.delete(:return_to_after_authenticating)) || target_domain&.auth_default_path.presence || root_path,
        notice: "Account creato. Ora hai accesso a #{target_domain&.authentication_sender_name || target_brand_node.title}.")
    rescue ActiveRecord::RecordInvalid => error
      @user.errors.add(:base, error.record.errors.full_messages.to_sentence) unless error.record == @user
      @subscription_domain = pending_subscription_domain
      render :new, status: :unprocessable_entity
    rescue BrandInvitations::Acceptance::Invalid, BrandAccesses::Authorization::NotAuthorized,
        BrandAccesses::Manager::NotAuthorized, BrandAccessGrants::Manager::NotAuthorized => error
      @user.errors.add(:base, error.message)
      render :new, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotUnique
      @user.errors.add(:base, "La registrazione è già stata completata o aggiornata. Riapri l’invito per accedere.")
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

    def require_registration_invitation!
      return if pending_invitation.present?

      redirect_to new_brand_access_request_path(authentication_context_link_params),
        alert: "In questa fase puoi creare un account soltanto dopo aver ricevuto un invito personale."
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
