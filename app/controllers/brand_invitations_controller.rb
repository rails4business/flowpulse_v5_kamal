class BrandInvitationsController < ApplicationController
  layout "landing"

  allow_unauthenticated_access only: :show

  def create
    domain = Domain.active.where(primary: true).where.not(node_id: nil).find(params[:domain_id])
    unless Current.user&.superadmin_user? || domain.node.administered_by?(Current.user)
      head :forbidden
      return
    end

    invitation, raw_token = BrandInvitation.issue!(
      brand_node: domain.node,
      source_domain: domain,
      email_address: params.require(:email_address),
      invited_by_user: Current.user,
      role_code: params[:role_code]
    )
    flash[:invitation_url] = invitation_url(invitation, raw_token)
    redirect_back fallback_location: root_path, notice: "Invito generato per #{invitation.email_address}. Copia e invia personalmente il collegamento."
  end

  def show
    @invitation = BrandInvitation.find_pending_by_token(params[:token])
    unless @invitation
      redirect_to root_path, alert: "L’invito è scaduto o non è più valido."
      return
    end

    session[:pending_brand_invitation_token] = params[:token]
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
