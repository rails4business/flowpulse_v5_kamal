class PagesController < ApplicationController
  allow_unauthenticated_access except: :viaggiatori

  layout :pages_layout
  dashboard_section :traveler, only: :viaggiatori
  def markpostura
  end 

  def markpostura_old
  end 

  def markposturastory
  end 

  def posturacorretta
  end 

  def flowpulse
  end

  def mari
  end

  def viaggiatori
    profile = Current.user.profile || Current.user.create_profile!(display_name: Current.user.email_address.to_s.split("@").first)
    @traveler_subscription_scope_domain = current_domain
    @traveler_subscriptions = TravelerSubscription.ordered_for(profile: profile, domain: @traveler_subscription_scope_domain)
  end

  private

    def pages_layout
      action_name == "viaggiatori" ? "application" : "landing"
    end
end
