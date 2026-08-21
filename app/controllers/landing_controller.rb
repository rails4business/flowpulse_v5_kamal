class LandingController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :load_posturacorretta_taxonomies, only: :posturacorretta


  def flowpulse
  end

  def flowpulse_content
    @article = DomainContentCatalog.find(
      "flowpulse",
      params[:slug],
      include_scheduled: Current.user&.superadmin_user? || false
    )
    return redirect_to(flowpulse_path, alert: "Contenuto non trovato") unless @article

    content_path = @article["content_path"]
    @content = File.read(content_path) if content_path.present? && File.file?(content_path)
  end

  def rails4b
  end

  def cantachetipassa
  end

  def markpostura
  
  end

  def markpostura_contents
    @content_author = Profile.find_by("LOWER(username) = ?", "markpostura")
    articles = DomainContentCatalog.for_author(
      "markpostura",
      include_scheduled: Current.user&.superadmin_user? || false
    )
    @contents_page = [params[:page].to_i, 1].max
    @contents_per_page = 20
    @contents_total = articles.size
    @contents_total_pages = [(@contents_total.to_f / @contents_per_page).ceil, 1].max
    @contents_page = @contents_total_pages if @contents_page > @contents_total_pages
    @author_articles = articles.slice((@contents_page - 1) * @contents_per_page, @contents_per_page) || []
  end

  def markpostura_content
    @article = DomainContentCatalog.find(
      "markpostura",
      params[:slug],
      include_scheduled: Current.user&.superadmin_user? || false
    )
    return redirect_to(markpostura_contents_path, alert: "Contenuto non trovato") unless @article

    content_path = @article["content_path"]
    @content = File.read(content_path) if content_path.present? && File.file?(content_path)
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
