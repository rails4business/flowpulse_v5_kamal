class BrandAccessesController < ApplicationController
  before_action :require_authentication

  def create
    domain = Domain.active.where.not(node_id: nil).find(params[:domain_id])
    unless invitation_or_administration_allows_access?(current_profile, domain)
      redirect_to new_brand_access_request_path(authentication_context_link_params),
        alert: "Per accedere a questo Brand serve un invito personale."
      return
    end
    access = grant_current_user_brand_access!(domain)
    Current.session&.update!(brand_access: access)

    redirect_back fallback_location: viaggiatori_path, notice: "Ora hai accesso a #{domain.site_title.presence || domain.display_hostname}."
  end

  def destroy
    access = Current.user.profile.brand_accesses.find(params[:id])
    brand_name = access.brand_node.title
    access.cancel!

    redirect_back fallback_location: viaggiatori_path, notice: "Hai rimosso l'accesso a #{brand_name}."
  end
end
