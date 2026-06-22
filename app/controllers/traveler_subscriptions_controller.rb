class TravelerSubscriptionsController < ApplicationController
  before_action :require_authentication

  def create
    domain = Domain.active.find(params[:domain_id])
    subscribe_current_user_to_domain(domain)

    redirect_back fallback_location: viaggiatori_path, notice: "Ti sei iscritto gratuitamente a #{domain.display_hostname}."
  end

  def destroy
    subscription = Current.user.profile.traveler_subscriptions.find(params[:id])
    domain_name = subscription.domain.display_hostname
    subscription.cancel!

    redirect_back fallback_location: viaggiatori_path, notice: "Hai rimosso l'iscrizione a #{domain_name}."
  end

  private

end
