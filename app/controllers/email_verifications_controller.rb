class EmailVerificationsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access
  before_action :set_verification, only: %i[show update]
  before_action :persist_authentication_context!, only: %i[show update]

  def sent
    @email_address = params[:email].to_s
  end

  def show
    @domain = @verification.requested_domain
  end

  def update
    user = @verification.user
    brand_access = nil

    User.transaction do
      @verification.lock!
      raise ActiveRecord::RecordInvalid, @verification unless @verification.pending?

      user.activate_verified_email!
      profile = user.profile || user.create_profile!(display_name: user.email_address.to_s.split("@").first)
      if @verification.brand_node.present?
        brand_access = grant_profile_brand_access_for_node!(
          profile,
          @verification.brand_node,
          source_domain: @verification.requested_domain
        )
      end
      invitation = BrandInvitation.find_by(id: @verification.metadata["brand_invitation_id"])
      invitation&.accept!(user)
      @verification.consume!
    end

    start_new_session_for(
      user,
      brand_access: brand_access,
      authentication_method: "verified_email"
    )
    session.delete(:pending_brand_invitation_token)
    redirect_to verification_destination, notice: verification_notice
  rescue ActiveRecord::RecordInvalid
    redirect_to new_user_path(authentication_context_link_params),
      alert: "Il collegamento di verifica è scaduto o è già stato utilizzato."
  end

  private

    def set_verification
      @verification = EmailVerification.find_pending_by_token(params[:token])
      return if @verification.present?

      redirect_to new_user_path(authentication_context_link_params),
        alert: "Il collegamento di verifica è scaduto o non è valido."
    end

    def verification_destination
      safe_authentication_return_to(@verification.return_to) ||
        @verification.requested_domain&.auth_default_path.presence ||
        root_path
    end

    def verification_notice
      domain = @verification.requested_domain
      brand_name = domain&.site_title.presence || domain&.display_hostname || @verification.brand_node&.title
      brand_name.present? ? "Email verificata. Benvenuto in #{brand_name}." : "Email verificata. Il tuo account è attivo."
    end
end
