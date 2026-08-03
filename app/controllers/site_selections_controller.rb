class SiteSelectionsController < ApplicationController
  def create
    domain = Domain.active.find(params[:domain_id])
    session[:override_domain_id] = domain.id
    redirect_to root_path, notice: "Sito selezionato: #{domain.site_title.presence || domain.display_hostname}."
  end
end
