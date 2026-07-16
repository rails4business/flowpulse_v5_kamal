class PosturacorrettaController < ApplicationController
  layout "landing"
  allow_unauthenticated_access

  def percorso; end
  def professionisti
    redirect_to posturacorretta_percorso_path
  end
  def contenuti; end
  def eventi; end
  def filosofia; end
  def progetti
    render :collabora
  end
  def collabora; end
end
