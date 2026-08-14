class PosturacorrettastartController < ApplicationController
  layout "landing"

  TABS = %w[home percorso accademia filosofia].freeze

  def index
    destination = case params[:tab]
    when "percorso" then posturacorretta_percorso_path
    when "accademia" then posturacorretta_path
    when "filosofia" then posturacorretta_eventi_path
    else posturacorretta_path
    end
    redirect_to destination, status: :moved_permanently
  end

  def one_month
    redirect_to(posturacorretta_path(chapter: params[:chapter]), status: :moved_permanently)
  end
end
