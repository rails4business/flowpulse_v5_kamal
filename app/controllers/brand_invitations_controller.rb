class BrandInvitationsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: :show

  def create
    domain = Domain.active.where(primary: true).where.not(node_id: nil).find(params[:domain_id])
    invitation, raw_token = BrandInvitations::Issuer.new(actor: Current.user).issue!(
      domain: domain, email_address: params.require(:email_address)
    )
    flash[:invitation_url] = invitation_url(invitation, raw_token)
    redirect_back fallback_location: root_path, notice: "Invito generato per #{invitation.email_address}. Copia e invia personalmente il collegamento."
  rescue BrandAccesses::Authorization::NotAuthorized
    head :forbidden
  rescue ActiveRecord::RecordInvalid, ArgumentError => error
    redirect_back fallback_location: root_path, alert: error.message
  end

  def show
    @invitation = BrandInvitation.find_pending_by_token(params[:token])
    unless @invitation
      session.delete(:pending_brand_invitation_token)
      redirect_to root_path, alert: "L’invito è scaduto o non è più valido."
      return
    end

    session[:pending_brand_invitation_token] = params[:token]
    remove_instance_variable(:@authentication_context_domain) if defined?(@authentication_context_domain)
    return unless require_matching_invitation_context!

    persist_authentication_context!
    destination = if BrandCredential.exists?(
      brand_node: @invitation.brand_node,
      email_address: @invitation.email_address
    )
      new_session_path(invitation: params[:token])
    else
      new_user_path(invitation: params[:token])
    end
    redirect_to destination
  end

  private

    def invitation_url(invitation, raw_token)
      options = { token: raw_token }
      if local_request?
        options.merge!(host: "localhost", port: request.optional_port, protocol: request.protocol)
      else
        options.merge!(host: invitation.source_domain.hostname, protocol: "https")
      end
      brand_invitation_url(**options)
    end
end
