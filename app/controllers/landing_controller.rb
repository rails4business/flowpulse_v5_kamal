class LandingController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :load_posturacorretta_taxonomies, only: :posturacorretta


  def flowpulse
  end

  def stato_di_salute
    @scopes = PosturacorrettaTaxonomies.load.fetch("scopes", {})
  end

  def stato_di_salute_course
    source = Rails.root.join("config/data/brands/posturacorretta/courses/percorso-integrato/course.yml")
    data = YAML.safe_load_file(source, permitted_classes: [], aliases: false) || {}
    original = data.fetch("contents", []).select { |item| item["parent_id"] == "il-tuo-stato-di-salute" }
      .reject { |item| item["slug"].in?(%w[matrice-per-orientarsi-salute-benessere tre-colori-professionisti-insegnanti]) }
      .sort_by { |item| item.fetch("position", 0) }
    domains = [
      ["salute-cura-riabilitazione", "Salute, cura e riabilitazione", "Osservare sicurezza, sintomi, autonomia e necessità di assistenza professionale."],
      ["prevenzione", "Prevenzione", "Riconoscere rischi, abitudini e azioni utili nella vita quotidiana, nel lavoro e nello sport."],
      ["performance", "Performance", "Osservare energia, attenzione, recupero e capacità di sostenere attività e obiettivi."],
      ["benessere", "Benessere", "Esplorare riposo, alimentazione, equilibrio emotivo e soddisfazione personale."],
      ["conoscenza-espressione-corpo", "Conoscenza ed espressione del corpo", "Imparare a riconoscere, descrivere e comunicare i segnali del corpo."],
      ["consapevolezza", "Consapevolezza", "Osservare l’incontro tra corpo, pensieri, emozioni, abitudini e scelte."],
      ["evoluzione-connessione", "Evoluzione e connessione", "Considerare relazioni, ambiente, comunità, natura, valori e direzione personale."]
    ].map.with_index do |(slug, title, description), index|
      { "slug" => slug, "title" => title, "description" => description, "position" => index + 5, "generated" => true }
    end
    @health_course_chapters = original + domains
    @health_course_chapter = @health_course_chapters.find { |item| item.fetch("slug") == params[:capitolo] }
    raise ActiveRecord::RecordNotFound, "Capitolo non trovato" if params[:capitolo].present? && @health_course_chapter.blank?

    if @health_course_chapter && !@health_course_chapter["generated"]
      root = Rails.root.join("config/data").cleanpath
      path = root.join(@health_course_chapter.fetch("content_path")).cleanpath
      @health_course_markdown = path.read.sub(/\A---\s*\n.*?\n---\s*\n/m, "") if path.to_s.start_with?("#{root}/") && path.file?
    end
  end

  def stato_di_salute_about
  end

  def inside_adventure
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    prototype = Rails.root.join("docs/private_prototypes/viste_html/inside-adventure.html").read
    development_styles = <<~CSS
      .development-banner{background:#f8e24c;color:#1b2b54;padding:10px 18px;text-align:center;font:600 .9rem/1.4 system-ui,-apple-system,"Segoe UI",sans-serif}
      .development-banner a{color:#1b2b54;font-weight:800;margin-left:10px;text-underline-offset:3px}
    CSS
    development_banner = '<aside class="development-banner">Brand in sviluppo in GeneraImpresa · contenuti, prezzi e percorsi sono ancora da verificare. <a href="/generaimpresa">Torna a GeneraImpresa →</a></aside>'
    prototype.sub!("</style>", "#{development_styles}</style>")
    prototype.sub!("<body>", "<body>#{development_banner}")
    prototype.sub!("<footer>WWW.????????.COM</footer>", '<footer><a class="lnk" href="/generaimpresa">Inside Adventure · un Brand in sviluppo in GeneraImpresa</a></footer>')

    render html: prototype.html_safe, layout: false
  end

  def flowpulse_projects
    projects = FlowpulseProjectRegistry.load.fetch("projects", [])
    visible_projects = projects.select do |project|
      project.fetch("visibility", "internal") == "public" || Current.user&.superadmin_user?
    end
    @flowpulse_projects_scope = params[:mondo] == "markpostura" ? "markpostura" : "all"
    @flowpulse_projects = if @flowpulse_projects_scope == "markpostura"
      visible_projects.select { |project| project["world"] == "markpostura" }
    else
      visible_projects
    end
  end

  def flowpulse_professionals
    professional_nodes = Node.published_public
      .professional
      .includes(:domains, :primary_professional_profile)
      .order(:title)
      .to_a

    configured_professionals = ChangelogRepository.catalog.values
      .select { |brand| brand.fetch("kind") == "professional" }
      .reject { |brand| professional_nodes.any? { |node| node.slug == brand.fetch("key") } }
      .sort_by { |brand| brand.fetch("label").downcase }

    @flowpulse_professionals = professional_nodes + configured_professionals
  end

  def flowpulse_contents
    redirect_to rails4b_contents_path, status: :moved_permanently
  end

  def flowpulse_content
    redirect_to rails4b_content_path(params[:slug]), status: :moved_permanently
  end

  def rails4b
    load_rails4b
    @rails4b_track = @rails4b_path.fetch("tracks").find { |track| track.fetch("slug") == params[:percorso] } || @rails4b_path.fetch("tracks").first
    @rails4b_track_steps = rails4b_steps_for(@rails4b_track)
  end

  def rails4b_contents
    load_rails4b
    visible_contents = @rails4b_content_catalog.fetch("items", []).select do |content|
      %w[published scheduled].include?(content.fetch("status")) || Current.user&.superadmin_user?
    end
    @rails4b_contents = visible_contents.sort_by { |content| content.fetch("publication_at") }.reverse.map do |content|
      content.merge("track_slug" => @rails4b_track_by_content_slug[content.fetch("slug")])
    end
  end

  def rails4b_ideas
    @rails4b_ideas = YAML.safe_load_file(Rails.root.join("config/data/rails4b/idee.yml"), permitted_classes: [], aliases: false).fetch("ideas")
  end

  def rails4b_track
    load_rails4b
    @rails4b_track = @rails4b_path.fetch("tracks").find { |track| track.fetch("slug") == params[:slug] }
    return redirect_to(rails4b_path, alert: "Percorso non trovato") unless @rails4b_track

    @rails4b_track_steps = rails4b_steps_for(@rails4b_track)
    @rails4b_article = @rails4b_track_steps.find { |content| content.fetch("slug") == params[:contenuto] } || @rails4b_track_steps.first
    return redirect_to(rails4b_path, alert: "Percorso non trovato") unless @rails4b_article

    load_rails4b_article_body
  end

  def rails4b_content
    if params[:slug] == "la-salute-non-e-un-lusso"
      return redirect_to posturacorretta_articolo_path(params[:slug]), status: :moved_permanently
    end

    load_rails4b
    @rails4b_track = @rails4b_path.fetch("tracks").find { |track| track.fetch("steps").any? { |step| step.fetch("content_slug") == params[:slug] } }
    @rails4b_article = @rails4b_contents_by_slug[params[:slug]]
    return redirect_to(rails4b_path, alert: "Contenuto non trovato") unless @rails4b_article
    return redirect_to(rails4b_path, alert: "Contenuto non trovato") if @rails4b_article.fetch("status") == "draft" && !Current.user&.superadmin_user?

    load_rails4b_article_body
  end

  def radioestesia
    load_radioestesia
    @radioestesia_page = params[:page].presence || "home"
    @radioestesia_page_data = @radioestesia.fetch("pages").fetch(@radioestesia_page)
    # I vecchi link con le tab puntano ora alla pagina Eventi.
    return redirect_to(radioestesia_page_path("eventi"), status: :moved_permanently) if @radioestesia_page == "contenuti" && params[:tab] == "eventi"

    load_radioestesia_timeline if @radioestesia_page.in?(%w[contenuti eventi])
    @radioestesia_journey = YAML.safe_load_file(Rails.root.join(@radioestesia_page_data.fetch("source")), permitted_classes: [], aliases: false).fetch("percorso") if @radioestesia_page_data["source"]
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

  def cantachetipassa_retirement_home
    render layout: false
  end

  def cantachetipassa_accordion
    root = Rails.root.join("config/data/brands/cantachetipassa/accordion").cleanpath
    index = YAML.safe_load_file(root.join("index.yml"), permitted_classes: [], aliases: false) || {}
    @accordion_pages = index.fetch("pages")
    @accordion_page_slug = params[:page].presence_in(@accordion_pages.map { |page| page.fetch("slug") }) || @accordion_pages.first.fetch("slug")
    @accordion_page = YAML.safe_load_file(root.join("pages", "#{@accordion_page_slug}.yml"), permitted_classes: [], aliases: false) || {}
    @accordion_chapters = @accordion_page.fetch("chapters", []).map do |chapter|
      source = root.join(chapter.fetch("source")).cleanpath
      next unless source.to_s.start_with?("#{root}/") && source.extname == ".md" && source.file?

      chapter.merge("content" => source.read)
    end.compact
    @accordion_study = YAML.safe_load_file(root.join("study.yml"), permitted_classes: [], aliases: true) || {}
    @accordion_study_paths = @accordion_study.fetch("paths", [])
    @accordion_study_path_slug = params[:percorso].presence_in(@accordion_study_paths.map { |path| path.fetch("slug") }) || @accordion_study_paths.first.fetch("slug")
    @accordion_study_path = @accordion_study_paths.find { |path| path.fetch("slug") == @accordion_study_path_slug }
    @accordion_pieces = @accordion_study.fetch("pieces", []).reject { |piece| piece.fetch("template", false) }.index_by { |piece| piece.fetch("slug") }
  end

  def giardino_del_corpo
    @garden_tab = %w[contenuti passati].include?(params[:tab]) ? "contenuti" : "eventi"
    garden_entries = garden_event_catalog
    @garden_events, @garden_contents = garden_entries.partition { |event| event["event_date"].blank? || event.fetch("event_date") >= Date.current }
    @garden_events.sort_by! { |event| [event["event_date"] || Date.new(9999, 12, 31), event.fetch("title", "")] }
    @garden_contents.sort_by! { |event| event.fetch("event_date") }.reverse!
    @garden_places = AcademyCurriculum.load.fetch("locations", {}).values.select do |place|
      Array(place["projects"]).include?("giardino-del-corpo")
    end
  end

  def markpostura
    render_editorial_site("markpostura_it")
  end

  def markpostura_presentation
    render_editorial_site("markpostura_it", path: "/presentazione")
  end

  def markpostura_timeline
    render_editorial_site("markpostura_it", path: "/timeline")
  end

  def markpostura_weekplan
    @markpostura = MarkposturaWeekPlan.load(include_private: Current.user&.superadmin_user? || false)
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
    @home_data = YAML.load_file(Rails.root.join("config/data/posturacorretta/home/home.yml"))
    @audiences = YAML.load_file(Rails.root.join("config/data/posturacorretta/shared/audiences.yml"))
  end

  def igieneposturale
    node = Node.find_by(slug: "igiene-posturale")
    return if node&.status == "published" && node.visibility == "public"

    response.set_header("X-Robots-Tag", "noindex, nofollow")
    destination = local_request? ? genera_impresa_path : "#{request.protocol}generaimpresa.it#{genera_impresa_path}"
    redirect_to destination, status: :found, allow_other_host: true
  end

  private

  def load_radioestesia
    response.set_header("X-Robots-Tag", "noindex, nofollow")
    @radioestesia = YAML.safe_load_file(Rails.root.join("config/data/radioestesia/site.yml"), permitted_classes: [], aliases: false) || {}
  end

  def load_rails4b
    @rails4b = YAML.safe_load_file(Rails.root.join("config/data/rails4b/landing.yml"), permitted_classes: [], aliases: false) || {}
    @rails4b_path = YAML.safe_load_file(Rails.root.join("config/data/rails4b/percorso.yml"), permitted_classes: [], aliases: false) || {}
    # Articoli e guide sono Content (vedi DomainContentCatalog::CONTENT_NODES); lo stato è quello dell'ambiente.
    contents = Content.joins(:node).where(nodes: { slug: DomainContentCatalog::CONTENT_NODES.fetch("rails4b") }, format: %w[post chapter])
      .includes(:parent).order(:position, :key).to_a
    @rails4b_content_catalog = { "items" => contents.map { |content| rails4b_item(content) } }
    @rails4b_contents_by_slug = @rails4b_content_catalog.fetch("items").index_by { |content| content.fetch("slug") }
    @rails4b_track_step_slugs = @rails4b_path.fetch("tracks").to_h do |track|
      [track.fetch("slug"), contents.select { |content| content.parent&.key == track.fetch("course_key") }.map(&:slug)]
    end
    @rails4b_track_by_content_slug = @rails4b_track_step_slugs.each_with_object({}) do |(track_slug, slugs), index|
      slugs.each { |slug| index[slug] = track_slug }
    end
  end

  # Una guida non pubblicata resta nel trenino come "in preparazione" (titolo sì, testo no), come i capitoli
  # dei corsi; un articolo non pubblicato è una bozza visibile solo al superadmin.
  def rails4b_item(content)
    published = content.publication_status == "published" && content.publication_visibility == "public"
    content.data.merge(
      "slug" => content.slug,
      "kind" => content.format == "chapter" ? "guida" : "articolo",
      "title" => content.title,
      "description" => content.description,
      "publication_at" => content.written_on&.iso8601,
      "status" => published ? "published" : (content.format == "chapter" ? "scheduled" : "draft"),
      "source_path" => content.source_path
    )
  end

  def rails4b_steps_for(track)
    @rails4b_track_step_slugs.fetch(track.fetch("slug")).each_with_index.map do |slug, index|
      @rails4b_contents_by_slug.fetch(slug).merge("number" => (index + 1).to_s)
    end
  end

  def load_rails4b_article_body
    source_path = @rails4b_article["source_path"].present? ? Rails.root.join(@rails4b_article.fetch("source_path")).cleanpath : nil
    content_root = Rails.root.join("config/data").to_s
    @rails4b_draft_preview = @rails4b_article.fetch("status") != "published" && Current.user&.superadmin_user?
    @rails4b_markdown = source_path.read if source_path && (@rails4b_article.fetch("status") == "published" || @rails4b_draft_preview) && source_path.to_s.start_with?("#{content_root}/") && source_path.file?
  end

  def load_radioestesia_timeline
    standalone_contents = @radioestesia.fetch("contents").reject { |content| content["content_type"] == "chapter" }
    @radioestesia_future_contents, @radioestesia_past_contents = standalone_contents.partition do |content|
      Date.iso8601(content.fetch("date")) >= Date.current
    end
    @radioestesia_future_contents.sort_by! { |content| content.fetch("date") }
    @radioestesia_past_contents.sort_by! { |content| content.fetch("date") }.reverse!
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

  def garden_event_catalog
    DomainEventCatalog.for_project(
      "giardino-del-corpo",
      include_drafts: Current.user&.superadmin_user? || false
    )
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
