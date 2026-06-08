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
  end

  private

    def pages_layout
      action_name == "viaggiatori" ? "application" : "landing"
    end
end
