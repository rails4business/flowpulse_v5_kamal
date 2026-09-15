class PosturacorrettaController < ApplicationController
  layout "landing"
  allow_unauthenticated_access

  # These listings load and filter a sizeable YAML catalog. Keep abusive crawls from
  # occupying every Puma thread before the expensive callbacks below are reached.
  rate_limit to: 24, within: 1.minute, only: %i[contenuti metodiche], by: -> { request.remote_ip }, with: -> { throttled_public_listing }
  rate_limit to: 120, within: 1.minute, only: %i[contenuti metodiche], by: -> { "posturacorretta-public-listings" }, with: -> { throttled_public_listing }

  before_action :load_academy_curriculum, only: %i[accademia accademia_modulo accademia_recensioni]
  before_action :load_methodologies, only: %i[metodiche metodica]
  before_action :load_projects, only: %i[progetti progetto]
  before_action :load_catalog, only: %i[contenuti corsi articolo]
  after_action :log_public_listing_request, only: %i[contenuti metodiche]
  helper_method :posturacorretta_public_professionals

  def accademia
    return unless params[:tab] == "guide"

    redirect_to posturacorretta_path(sezione: "accademia", capitolo: "educazione"), status: :moved_permanently
  end
  def accademia_recensioni; end
  def accademia_modulo
    @module = @academy_modules.find { |m| m["slug"] == params[:slug] }
    return redirect_to posturacorretta_accademia_path, alert: "Modulo non trovato" unless @module
  end
  def percorso
    return redirect_to(posturacorretta_percorsi_sul_territorio_path) if params[:page] == "territorio"

    if params[:page].present?
      chapter = { "inizia" => "inizia", "linee-guida" => "quale-percorso" }.fetch(params[:page], params[:page])
      return redirect_to(posturacorretta_path(sezione: "percorso", capitolo: chapter), status: :moved_permanently)
    end

    @selected_tab = "percorso"
    @standalone_percorso = true
    render "posturacorrettastart/index"
  end

  def percorso_come_funziona
    if params[:page].present?
      return redirect_to posturacorretta_path(sezione: "percorso", capitolo: params[:page]), status: :moved_permanently
    end

    render "posturacorretta/percorso_come_funziona"
  end
  def percorsi_sul_territorio
    @territory_tab = params[:tab].presence_in(%w[people places]) || "people"
    return redirect_to(posturacorretta_insegnanti_path, status: :moved_permanently) if @territory_tab == "people"
    @professional_area = params[:area].presence_in(%w[all percorso accademia contenuti eventi metodiche]) || "all"
    @territory_domain = Domain.active.find_by(hostname: "posturacorretta.org")

    if @territory_domain
      @territory_people = Brands::Posturacorretta::DirectoryPerson.where(domain: @territory_domain, visibility: "public").order(:name)
      @territory_places = Brands::Posturacorretta::DirectoryPlace.where(domain: @territory_domain, visibility: "public").order(:city, :name)
    else
      @territory_people = []
      @territory_places = []
    end
    @professional_sections_by_slug = posturacorretta_professional_sections
    existing_slugs = @territory_people.map(&:slug)
    @territory_catalog_people = posturacorretta_public_professionals.reject { |professional| existing_slugs.include?(professional.fetch("slug")) }

    if @professional_area != "all"
      @territory_people = @territory_people.select { |person| Array(person.listing_sections).include?(@professional_area) }
      @territory_catalog_people = @territory_catalog_people.select do |professional|
        @professional_sections_by_slug.fetch(professional.fetch("slug"), []).include?(@professional_area)
      end
    end

    centers_path = Rails.root.join("config/data/posturacorretta/accademia/centers.yml")
    centers_data = centers_path.file? ? YAML.safe_load_file(centers_path, permitted_classes: [], aliases: false) || {} : {}
    @territory_catalog_places = centers_data.fetch("centers", {}).values.select do |place|
      place["city"] != "Online" && Array(place["projects"]).include?("posturacorretta")
    end
  end

  def insegnanti
    curriculum = AcademyCurriculum.load
    @teachers = curriculum.fetch("teachers", {}).values.select { |teacher| teacher.fetch("public", true) }
    @academy_modules_by_slug = curriculum.fetch("modules", []).index_by { |mod| mod.fetch("slug") }
  end

  def insegnante
    curriculum = AcademyCurriculum.load
    @teacher = curriculum.fetch("teachers", {}).fetch(params[:slug], nil)
    return redirect_to(posturacorretta_insegnanti_path, alert: "Insegnante non trovato") unless @teacher&.fetch("public", true)

    modules_by_slug = curriculum.fetch("modules", []).index_by { |mod| mod.fetch("slug") }
    @teacher_modules = @teacher.fetch("active_modules", []).filter_map { |slug| modules_by_slug[slug] }
    @teacher_centers = curriculum.fetch("locations", {}).values.select do |center|
      Array(center["projects"]).include?("posturacorretta") &&
        (Array(center["active_modules"]) & @teacher.fetch("active_modules", [])).any?
    end
  end

  def professionisti
    redirect_to percorso_integrato_professionals_path, status: :moved_permanently
  end
  
  def professionista
    redirect_to percorso_integrato_professional_path(params[:slug]), status: :moved_permanently
  end

  def dash
  end

  def primo_mese
    guide_data = YAML.safe_load_file(
      Rails.root.join("config/data/posturacorretta/guide/indice.yml"),
      permitted_classes: [],
      aliases: false
    ) || {}
    first_month = guide_data.fetch("sections", []).find { |section| section["id"] == "primo_mese" }
    @first_month_chapters = first_month&.fetch("items", []) || []
  end

  def metodiche
    return unless params[:tab] == "how"

    redirect_to posturacorretta_path(sezione: "metodiche", capitolo: "introduzione"), status: :moved_permanently
  end
  def metodica
    @methodology = @methodologies_by_slug[params.fetch(:slug)]
    return redirect_to posturacorretta_metodiche_path, alert: "Metodica non trovata" unless @methodology
  end
  def contenuti
    if params[:categoria] == "corsi"
      return redirect_to posturacorretta_corsi_path(request.query_parameters.except("categoria")), status: :moved_permanently
    end

    @content_catalog_mode = "contents"
    prepare_content_catalog
  end

  def corsi
    @content_catalog_mode = "courses"
    prepare_content_catalog
    render :contenuti
  end

  def prepare_content_catalog
    taxonomy_path = Rails.root.join("config/data/posturacorretta/contenuti/tassonomia.yml")
    @content_taxonomy = YAML.safe_load_file(taxonomy_path, permitted_classes: [], aliases: false) || {}
    posturacorretta_domain = Domain.active.find_by(hostname: "posturacorretta.org")
    @content_directory_people = posturacorretta_domain ? Brands::Posturacorretta::DirectoryPerson.where(domain: posturacorretta_domain, visibility: "public").order(:name) : []
    @content_directory_places = posturacorretta_domain ? Brands::Posturacorretta::DirectoryPlace.where(domain: posturacorretta_domain, visibility: "public").order(:city, :name) : []
    @content_people_filter_options = @content_directory_people.map { |person| [person.metadata.fetch("content_creator_key", person.slug), person.name] }
    existing_keys = @content_people_filter_options.map(&:first)
    @content_people_filter_options.concat(
      posturacorretta_public_professionals.reject { |professional| existing_keys.include?(professional.fetch("slug")) }.map { |professional| [professional.fetch("slug"), professional.fetch("name")] }
    )
  end
  def articolo
    @article = nil
    @category_key = nil
    @catalog.each do |cat_key, category|
      found = category[:articles].find { |a| a[:slug] == params[:slug] }
      if found
        @article = found
        @category_key = cat_key
        break
      end
    end
    return redirect_to posturacorretta_contenuti_path, alert: "Articolo non trovato" unless @article

    markdown_file = posturacorretta_article_file(@article)
    @content = File.exist?(markdown_file) ? File.read(markdown_file) : nil
  end
  def eventi
    if params[:tab] == "how"
      return redirect_to(posturacorretta_path(sezione: "eventi", capitolo: "introduzione"), status: :moved_permanently)
    end

    data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/eventi/eventi.yml"), permitted_classes: [], aliases: false) || {}
    catalog_events = DomainEventCatalog.for_domain(
      "posturacorretta",
      include_drafts: Current.user&.superadmin_user? || false
    )
    @events = catalog_events
    @places = data.fetch("places", [])
    @teachers = data.fetch("teachers", [])
    @event_filter_taxonomy = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/contenuti/tassonomia.yml"), permitted_classes: [], aliases: false) || {}
  end
  def libro
    taxonomies = PosturacorrettaTaxonomies.load
    @scopes = taxonomies.fetch("scopes", {})
    @areas = taxonomies.fetch("areas", {})

    paradigms_path = Rails.root.join("config/data/posturacorretta/guide/02_progetto/01_paradigmi_e_matrice.md")
    if paradigms_path.file?
      paradigms_content = paradigms_path.read
      @vision_paradigms, @vision_matrix = paradigms_content.split(/^# La Matrice\s*$/i, 2)
    end
  end
  def libri
    @books_tab = params[:tab].presence_in(%w[nostri consigliati]) || "nostri"
    @books_view = params[:view].presence_in(%w[grid list]) || "grid"
    @books_editor = Current.user&.superadmin_user? || false
    @owned_books = load_owned_books.sort_by { |b| b.fetch("status", "draft") == "published" ? 0 : 1 }

    library_path = Rails.root.join("config/data/posturacorretta/libri_pubblicati/biblioteca_postura.yml")
    library = library_path.file? ? YAML.safe_load_file(library_path, permitted_classes: [], aliases: false) || {} : {}
    raw_recommended = visible_library_entries(library.fetch("books", []))
    @library_publishers = visible_library_entries(library.fetch("publishers", []))

    @book_query = params[:q].to_s.strip
    @selected_book_categories = Array(params[:categories]).compact_blank
    @selected_book_languages = Array(params[:languages]).compact_blank
    @selected_book_publishers = Array(params[:publishers]).compact_blank

    @book_category_options = raw_recommended.filter_map { |book| book["category"].presence }.uniq.sort
    @book_language_options = raw_recommended.flat_map { |book| book["language"].to_s.split(%r{\s*/\s*}) }.compact_blank.uniq.sort
    @book_publisher_options = (@library_publishers.filter_map { |publisher| publisher["name"].presence } + raw_recommended.filter_map { |book| book["publisher"].presence }).uniq.sort

    @recommended_books = filter_recommended_books(raw_recommended).sort_by { |b| b.fetch("status", "draft") == "published" ? 0 : 1 }
    @recommended_books_total = @recommended_books.size
  end
  def progetti
    root = Rails.root.join("config/data/posturacorretta/progetti")
    @page_data = YAML.safe_load_file(root.join("page.yml"), permitted_classes: [], aliases: false) || {}
  end
  def progetto
    @project = @projects.find { |project| project["slug"] == params[:slug] }
    return redirect_to posturacorretta_progetti_path, alert: "Progetto non trovato" unless @project

    requested_tab = %w[overview phases activities].include?(params[:tab]) ? params[:tab] : "overview"
    requested_tab = "phases" if %w[progress realization].include?(params[:tab])
    @project_tab = @project["generaimpresa_origin"] == "historical_import" ? "overview" : requested_tab
    requested_phase = params[:tab] == "realization" ? "implementation" : params[:phase]
    @project_phase = %w[planning funding implementation testing launch repayment].include?(requested_phase) ? requested_phase : "planning"
    @activity_status = %w[upcoming completed cancelled].include?(params[:activity_status]) ? params[:activity_status] : nil
    @data_commitments = if @project["generaimpresa_origin"] == "generaimpresa"
      Brands::Impegno::Commitment.for_genera_impresa_project(@project.fetch("slug")).order(:starts_at)
    else
      Brands::Impegno::Commitment.none
    end
  end
  def collabora; end
  def collabora_professionisti; end
  def collabora_professionisti_guida
    chapter = {
      "percorso-integrato" => "percorso-integrato",
      "contenuti-video" => "contenuti",
      "promuovi-metodica-professione" => "metodica-professione",
      "eventi" => "eventi"
    }[params[:slug]]
    return redirect_to(posturacorretta_collabora_professionisti_path, alert: "Approfondimento non trovato") unless chapter

    redirect_to posturacorretta_path(sezione: "collabora", capitolo: chapter), status: :moved_permanently
  end
  def collabora_digital
    load_projects
    @freelance_tasks = []

    @projects.each do |project|
      %w[planning_activities funding_activities operational_activities].each do |phase|
        activities = project[phase] || []
        activities.each do |activity|
          if activity["delega"] == true && activity["status"] == "pending"
            @freelance_tasks << {
              project_name: project["name"],
              project_slug: project["slug"],
              title: activity["title"],
              type: activity["type"],
              budget: activity["budget"],
              deadline: activity["deadline"],
              notes: activity["notes"]
            }
          end
        end
      end
    end
  end

  private

  def throttled_public_listing
    payload = {
      event: "public_listing_throttled",
      path: request.path,
      ip_hash: anonymized_request_ip,
      user_agent: request.user_agent.to_s.first(180)
    }
    Rails.logger.warn(payload.to_json)

    render plain: "Troppe richieste. Riprova tra poco.", status: :too_many_requests
  end

  def log_public_listing_request
    payload = {
      event: "public_listing_request",
      path: request.path,
      status: response.status,
      filter_keys: request.query_parameters.keys.sort,
      ip_hash: anonymized_request_ip,
      user_agent: request.user_agent.to_s.first(180),
      referrer_host: referrer_host
    }
    Rails.logger.info(payload.to_json)
  end

  def anonymized_request_ip
    Digest::SHA256.hexdigest("#{Rails.application.secret_key_base}:#{request.remote_ip}").first(16)
  end

  def referrer_host
    URI.parse(request.referer).host if request.referer.present?
  rescue URI::InvalidURIError
    nil
  end

  def posturacorretta_professional_sections
    sections = Hash.new { |hash, slug| hash[slug] = [] }
    append_professional_section(sections, "config/data/posturacorretta/collegamenti/servizi.yml", "paths", "professional_slug", "percorso")
    append_professional_section(sections, "config/data/posturacorretta/collegamenti/contenuti.yml", "content_connections", "professional_slug", "contenuti")

    events_path = Rails.root.join("config/data/posturacorretta/eventi/eventi.yml")
    if events_path.file?
      events = YAML.safe_load_file(events_path, permitted_classes: [], aliases: false).to_h.fetch("events", [])
      events.flat_map { |event| Array(event["professional_slugs"]) }.each { |slug| sections[slug] << "eventi" }
    end

    methodologies_path = Rails.root.join("config/data/posturacorretta/metodiche/professionisti.yml")
    if methodologies_path.file?
      professionals = YAML.safe_load_file(methodologies_path, permitted_classes: [], aliases: false).to_h.fetch("professionals", [])
      professionals.each { |professional| sections[professional["slug"]] << "metodiche" }
    end

    teachers_path = Rails.root.join("config/data/posturacorretta/accademia/teachers.yml")
    if teachers_path.file?
      teachers = YAML.safe_load_file(teachers_path, permitted_classes: [], aliases: false).to_h.fetch("teachers", {})
      teachers.each_key { |slug| sections[slug] << "accademia" }
    end

    sections.transform_values(&:uniq)
  end

  def append_professional_section(sections, relative_path, collection_key, slug_key, section)
    path = Rails.root.join(relative_path)
    return unless path.file?

    entries = YAML.safe_load_file(path, permitted_classes: [], aliases: false).to_h.fetch(collection_key, [])
    entries.each { |entry| sections[entry[slug_key]] << section if entry[slug_key].present? }
  end

  def load_owned_books
    Dir.glob(Rails.root.join("config/data/books/*/book.yml")).sort.filter_map do |path|
      metadata_path = Pathname(path)
      metadata = YAML.safe_load_file(metadata_path, permitted_classes: [], aliases: false) || {}
      slug = metadata_path.dirname.basename.to_s
      status = metadata.fetch("status", "draft")
      next unless @books_editor || status == "published"
      next if slug.start_with?("old-") || slug.start_with?("test-")

      metadata.merge("slug" => slug, "status" => status)
    rescue StandardError
      nil
    end
  end

  def visible_library_entries(entries)
    entries.select { |entry| @books_editor || entry.fetch("status", "draft") == "published" }
  end

  def filter_recommended_books(books)
    books.select do |book|
      searchable = [book["title"], book["author"], book["publisher"], book["category"], book["language"]].compact.join(" ")
      languages = book["language"].to_s.split(%r{\s*/\s*})
      query_match = @book_query.blank? || searchable.downcase.include?(@book_query.downcase)
      category_match = @selected_book_categories.empty? || @selected_book_categories.include?(book["category"])
      language_match = @selected_book_languages.empty? || (@selected_book_languages & languages).any?
      publisher_match = @selected_book_publishers.empty? || @selected_book_publishers.include?(book["publisher"])
      query_match && category_match && language_match && publisher_match
    end
  end

  def collect_aside_slugs(items)
    items.flat_map do |item|
      [item["slug"], *collect_aside_slugs(item.fetch("children", []))].compact
    end
  end

  def find_aside_item(items, slug)
    items.each do |item|
      return item if item["slug"] == slug
      if item["children"].present?
        found = find_aside_item(item["children"], slug)
        return found if found
      end
    end
    nil
  end

  def load_catalog
    catalog_path = Rails.root.join("config/data/posturacorretta/contenuti/catalog.yml")
    raw_catalog = File.exist?(catalog_path) ? YAML.safe_load_file(catalog_path, permitted_classes: [], aliases: false, symbolize_names: true) || {} : {}
    catalog_editor = Current.user&.superadmin_user? || false

    processed_catalog = raw_catalog.transform_values do |category|
      indexed_articles = category.fetch(:articles, []).each_with_index.filter_map do |article, index|
        publication_date = catalog_publication_date(article) || catalog_date(article, :data_pubblicazione_video)
        video_recording_date = catalog_date(article, :data_registrazione_video)
        video_publication_date = catalog_date(article, :data_pubblicazione_video)
        scheduled = publication_date.present? && publication_date > Date.current
        next if scheduled && !catalog_editor

        decorated = article.merge(
          _publication_date: publication_date,
          _publication_label: publication_date&.strftime("%d/%m/%Y"),
          _video_recording_date: video_recording_date,
          _video_recording_label: video_recording_date&.strftime("%d/%m/%Y"),
          _video_publication_date: video_publication_date,
          _video_publication_label: video_publication_date&.strftime("%d/%m/%Y"),
          _scheduled: scheduled
        )
        [decorated, index]
      end

      sorted_articles = indexed_articles.sort_by do |article, original_index|
        publication_date = article[:_publication_date]
        if article[:_scheduled]
          [0, publication_date.jd, original_index]
        elsif publication_date
          [1, -publication_date.jd, original_index]
        else
          [2, 0, original_index]
        end
      end.map(&:first)

      category.merge(articles: sorted_articles)
    end

    # Crea la sezione dinamica 'tutti' con l'unione di TUTTI i video e i post .md pubblici
    video_archive = processed_catalog.dig(:tutti, :articles) || []
    category_articles = processed_catalog.except(:tutti, :non_in_elenco, :corsi).values.flat_map { |cat| cat[:articles] || [] }
    event_items = DomainEventCatalog.for_domain(
      "posturacorretta",
      include_drafts: Current.user&.superadmin_user? || false
    ).filter_map do |event|
      event_date = event.fetch("event_date", nil)
      next unless event_date

      event_type = event["event_type"].presence || event["format"].presence || "evento"
      {
        slug: "evento-#{event.fetch("slug")}",
        title: event.fetch("title"),
        excerpt: event["description"].presence || "Dettagli e programma in aggiornamento.",
        author: event.fetch("organizer_usernames", []).first.presence || "markpostura",
        item_type: "event",
        event_type: event_type,
        format: "event",
        url: posturacorretta_eventi_path,
        subcategory: event_type.to_s.humanize,
        _publication_date: event_date,
        _publication_label: event_date.strftime("%d/%m/%Y"),
        _scheduled: event_date > Date.current,
        area: Array(event["aree"]).first,
        paradigm: Array(event["paradigmi"]).first,
        places: [event["place_slug"]].compact,
        professionals: Array(event["professional_slugs"]),
        methodologies: [],
        channel: "posturacorretta",
        platform: "evento"
      }
    end
    all_articles = (category_articles + video_archive + event_items).uniq { |art| art[:slug] }
    
    sorted_all_articles = all_articles.sort_by do |art|
      pub_date = art[:_publication_date]
      pub_date ? [0, -pub_date.jd, art[:title].to_s] : [1, 0, art[:title].to_s]
    end

    @catalog = {
      tutti: {
        label: "Tutti",
        eyebrow: "Tutti i contenuti",
        icon: "📚",
        color: "blue",
        description: "Esplora tutti i post, video e approfondimenti in ordine di pubblicazione.",
        subcategories: ["Tutti"],
        articles: sorted_all_articles
      }
    }.merge(processed_catalog.except(:tutti, :non_in_elenco))
  end

  def catalog_publication_date(article)
    source = article[:source].presence || posturacorretta_article_source(article[:slug])
    match = File.basename(source.to_s).match(/\A(\d{4}-\d{2}-\d{2})-/)
    Date.iso8601(match[1]) if match
  rescue ArgumentError
    nil
  end

  def posturacorretta_article_file(article)
    source = article[:source].presence || posturacorretta_article_source(article[:slug]) || "articoli/#{article[:slug]}.md"
    Rails.root.join("config/data/posturacorretta/contenuti", source)
  end

  def posturacorretta_article_source(slug)
    root = Rails.root.join("config/data/posturacorretta/contenuti")
    path = Dir.glob(root.join("articoli", "*", "????-??-??-#{slug}.md")).sort.last
    Pathname(path).relative_path_from(root).to_s if path
  end

  def catalog_date(article, key)
    value = article[key].presence
    Date.iso8601(value.to_s) if value.present?
  rescue ArgumentError
    nil
  end

  def posturacorretta_public_professionals
    path = Rails.root.join("config/data/posturacorretta/posturacorretta_professionisti.yml")
    return [] unless path.file?

    data = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
    data.fetch("professionals", []).select { |professional| professional["public"] }
  end

  def load_projects
    root = Rails.root.join("config/data/posturacorretta/progetti")
    data = PosturacorrettaProjectCatalog.load
    participants_data = YAML.safe_load_file(root.join("progetti_partecipanti.yml"), permitted_classes: [], aliases: false) || {}
    @projects = data.fetch("projects", [])
    @project_participants = participants_data.fetch("participants", [])
    @project_participants_by_slug = @project_participants.index_by { |participant| participant.fetch("slug") }
  end

  def load_academy_curriculum
    @academy_curriculum = AcademyCurriculum.load
    @academy_paths = @academy_curriculum.fetch("paths", [])
    @academy_path = @academy_paths.first
    @academy_areas = @academy_path ? @academy_path.fetch("areas", []) : []
    @academy_modules = @academy_areas.flat_map { |area| area.fetch("modules") }
    @academy_modules = @academy_curriculum.fetch("modules") if @academy_modules.empty?
    @academy_teachers = @academy_curriculum.fetch("teachers", {})
    @academy_locations = @academy_curriculum.fetch("locations", {})
  end

  def load_methodologies
    @methodologies_data = PosturacorrettaMethodologies.load
    @methodologies = @methodologies_data.fetch("methodologies")
    @methodologies_by_slug = @methodologies_data.fetch("methodologies_by_slug")
    @methodology_professionals = @methodologies_data.fetch("professionals")
    @methodology_schools = @methodologies_data.fetch("schools")
    @methodology_filter_taxonomy = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/contenuti/tassonomia.yml"), permitted_classes: [], aliases: false) || {}
  end
end
