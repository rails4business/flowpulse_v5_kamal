class LandingController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :load_posturacorretta_taxonomies, only: :posturacorretta


  def flowpulse
  end

  def markpostura
  
  end

  def markpostura_old

  end

  def markposturastory
   
  end

  def posturacorretta
    @home_data = YAML.load_file(Rails.root.join('config/data/posturacorretta/home/home.yml'))
    @audiences = YAML.load_file(Rails.root.join('config/data/posturacorretta/shared/audiences.yml'))
  end

  def igieneposturale
 
  end

  private

  def load_posturacorretta_taxonomies
    @posturacorretta_taxonomies = PosturacorrettaTaxonomies.load
  end
end
