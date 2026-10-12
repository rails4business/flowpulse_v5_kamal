class BrandAccessesController < ApplicationController
  before_action :require_authentication

  def create
    domain = Domain.active.where.not(node_id: nil).find(params[:domain_id])
    grant_current_user_brand_access!(domain)

    redirect_back fallback_location: viaggiatori_path, notice: "Ora hai accesso a #{domain.site_title.presence || domain.display_hostname}."
  end

  def destroy
    access = Current.user.profile.brand_accesses.find(params[:id])
    brand_name = access.brand_node.title
    access.cancel!

    redirect_back fallback_location: viaggiatori_path, notice: "Hai rimosso l'accesso a #{brand_name}."
  end
end
