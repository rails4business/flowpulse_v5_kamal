class LandingController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :load_posturacorretta_taxonomies, only: :posturacorretta


  def flowpulse
    @flowpulse_articles = visible_flowpulse_articles
  end

  def flowpulse_contents
    @domain_articles = DomainContentCatalog.for_domain(
      "flowpulse",
      include_scheduled: Current.user&.superadmin_user? || false
    )
  end

  def flowpulse_content
    @article = DomainContentCatalog.find(
      "flowpulse",
      params[:slug],
      include_scheduled: Current.user&.superadmin_user? || false
    )
    return redirect_to(flowpulse_contents_path, alert: "Contenuto non trovato") unless @article

    content_path = @article["content_path"]
    @content = File.read(content_path) if content_path.present? && File.file?(content_path)
  end

  def rails4b
  end

  def radioestesia
    load_radioestesia
    @radioestesia_page = params[:page].presence || "home"
    @radioestesia_page_data = @radioestesia.fetch("pages").fetch(@radioestesia_page)
    load_radioestesia_timeline if @radioestesia_page == "contenuti"
  end

  def radioestesia_content
    load_radioestesia
    @radioestesia_page = "contenuti"
    @radioestesia_content = @radioestesia.fetch("contents").find { |content| content.fetch("slug") == params[:slug] }
    return redirect_to(radioestesia_page_path("contenuti"), alert: "Contenuto non trovato") unless @radioestesia_content

    @radioestesia_course = if Array(@radioestesia_content["chapters"]).present?
      @radioestesia_content
    else
      @radioestesia.fetch("contents").find { |content| Array(content["chapters"]).include?(@radioestesia_content.fetch("slug")) }
    end
    @radioestesia_chapters = @radioestesia.fetch("contents").index_by { |content| content.fetch("slug") }
    @radioestesia_purchase = radioestesia_purchase_for(@radioestesia_content)

    content_file = Rails.root.join("config/data/radioestesia", @radioestesia_content.fetch("source")).cleanpath
    @radioestesia_markdown = content_file.read if content_file.to_s.start_with?(Rails.root.join("config/data/radioestesia").to_s) && content_file.file?
  end

  def cantachetipassa
  end

  def giardino_del_corpo
    @garden_events = visible_garden_events
    @garden_places = AcademyCurriculum.load.fetch("locations", {}).values.select do |place|
      Array(place["projects"]).include?("giardino-del-corpo")
    end
  end

  def markpostura
    @markpostura_events = visible_markpostura_events.first(3)
  end

  def markpostura_events
    @markpostura_events = visible_markpostura_events
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

  def load_radioestesia
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    @radioestesia = YAML.safe_load_file(Rails.root.join("config/data/radioestesia/site.yml"), permitted_classes: [], aliases: false) || {}
  end

  def load_radioestesia_timeline
    standalone_contents = @radioestesia.fetch("contents").reject { |content| content["content_type"] == "chapter" }
    @radioestesia_future_contents, @radioestesia_past_contents = standalone_contents.partition do |content|
      Date.iso8601(content.fetch("date")) >= Date.current
    end
    @radioestesia_future_contents.sort_by! { |content| content.fetch("date") }
    @radioestesia_past_contents.sort_by! { |content| content.fetch("date") }.reverse!
    @radioestesia_timeline_tab = params[:tab].to_s == "passati" ? "passati" : "prossimi"
  end

  def radioestesia_purchase_for(content)
    return unless content["access"] == "Pagamento"

    annual = @radioestesia.dig("site", "membership")
    if content["content_type"] == "event"
      future_event = Date.iso8601(content.fetch("date")) >= Date.current
      price = future_event ? content.fetch("event_price_eur") : content.fetch("online_material_price_eur")
      return { kind: "online_material_pending", annual_price_eur: annual.fetch("price_eur"), event_discount_percent: annual.fetch("event_discount_percent") } if price.blank?

      return {
        kind: future_event ? "event" : "online_material",
        price_eur: price,
        annual_price_eur: annual.fetch("price_eur"),
        event_discount_percent: annual.fetch("event_discount_percent"),
        annual_event_price_eur: future_event ? (price * (100 - annual.fetch("event_discount_percent")) / 100.0).round(2) : nil,
        annual_event_total_eur: future_event ? (annual.fetch("price_eur") + (price * (100 - annual.fetch("event_discount_percent")) / 100.0).round(2)).round(2) : nil
      }
    end

    {
      kind: content["content_type"] == "course" ? "course" : "content",
      price_eur: content.fetch("price_eur"),
      annual_price_eur: annual.fetch("price_eur"),
      event_discount_percent: annual.fetch("event_discount_percent")
    }
  end

  def visible_flowpulse_articles
    DomainContentCatalog.for_domain(
      "flowpulse",
      include_scheduled: Current.user&.superadmin_user? || false
    ).first(3)
  end

  def visible_garden_events
    DomainEventCatalog.for_project(
      "giardino-del-corpo",
      include_drafts: Current.user&.superadmin_user? || false
    ).select { |event| event["event_date"].blank? || event.fetch("event_date") >= Date.current }
     .sort_by { |event| [event["event_date"] || Date.new(9999, 12, 31), event.fetch("title", "")] }
  end

  def visible_markpostura_events
    DomainEventCatalog.for_organizer(
      "markpostura",
      include_drafts: Current.user&.superadmin_user? || false
    ).select { |event| event["event_date"].blank? || event.fetch("event_date") >= Date.current }
     .sort_by { |event| [event["event_date"] || Date.new(9999, 12, 31), event.fetch("title", "")] }
  end

  def load_posturacorretta_taxonomies
    @posturacorretta_taxonomies = PosturacorrettaTaxonomies.load
  end
end
