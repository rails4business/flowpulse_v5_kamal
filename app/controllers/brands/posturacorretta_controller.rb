module Brands
  class PosturacorrettaController < ::PosturacorrettaController
    FIRST_MONTH_BOOK_SLUG = "postura-corretta-in-un-mese".freeze
    FIRST_MONTH_BOOK_CHAPTERS = {
      "00-incontro-salute-metodiche" => "incontro-salute-metodiche",
      "02-benefici" => "benefici-postura-corretta",
      "04-disallineamento" => "postura-strumento-lettura",
      "05-metodiche" => "insegnamenti-metodiche-posturali",
      "01-errori" => "tre-errori-percorso-posturale",
      "00-postura-punto-incontro" => "postura-punto-incontro",
      "00-percorso-o-interventi-separati" => "percorso-o-interventi-separati",
      "rosso-verde-blu" => "rosso-verde-blu",
      "00-trovare-il-giusto-punto-di-vista" => "giusto-punto-di-vista",
      "00-ultima-sconfitta" => "giusto-punto-di-vista",
      "06-visione" => "nuovo-punto-di-vista",
      "00-da-dove-iniziare" => "prossimo-passo",
      "03-da-dove-iniziare" => "prossimo-passo"
    }.freeze
    PERCORSO_INTEGRATO_DOCS = {
      "domanda-da-dove-comincio" => "da-dove-comincio",
      "domanda-senza-diagnosi" => "senza-diagnosi",
      "domanda-insegnante-professionista" => "insegnante-professionista",
      "domanda-coinvolgere-professionista" => "coinvolgere-professionista",
      "domanda-durata-programma" => "durata-programma",
      "tutor-valutare-richiesta" => "valutare-richiesta",
      "tutor-scheda-chiamata" => "scheda-chiamata",
      "tutor-proposta-percorso" => "modello-proposta",
      "professionisti-iniziare-percorso" => "iniziare-percorso",
      "professionisti-responsabile-percorso" => "responsabile-percorso",
      "professionisti-aprire-programma" => "aprire-programma",
      "professionisti-definire-proposta" => "definire-proposta",
      "professionisti-invitare-professionista" => "invitare-professionista",
      "professionisti-usare-diario" => "usare-diario",
      "professionisti-ragionamento-fisiologico" => "ragionamento-fisiologico",
      "professionisti-misurare-risultati" => "misurare-risultati",
      "professionisti-chiudere-programma" => "chiudere-programma",
      "professionisti-chiudere-percorso" => "chiudere-percorso",
      "professionisti-aderisci-linee-guida" => "aderire-linee-guida",
      "stop-al-dolore" => "stop-al-dolore",
      "prevenzione" => "prevenzione",
      "performance" => "performance",
      "espressione" => "attivita-corporee",
      "consapevolezza" => "postura-fisiologia",
      "connessione" => "corpo-ambiente"
    }.freeze

    def three_projects
      render "brands/posturacorretta/three_projects"
    end

    def guide
      return redirect_first_month_to_book if first_month_guide_request?
      return redirect_percorso_integrato_docs if params[:sezione] == "percorso"

      load_home_index
      requested_section = params[:sezione].presence || section_for_legacy_chapter(params[:chapter])
      requested_chapter = params[:capitolo].presence || params[:chapter]
      @current_section = @home_sections.find { |section| section.fetch("id") == requested_section }
      @current_section ||= @home_sections.first
      return redirect_to(posturacorretta_path, alert: "La documentazione è in preparazione.") unless @current_section
      @section_chapters = flatten_guide_items(@current_section.fetch("items", []))
      @current_chapter = @section_chapters.find do |item|
        [item.fetch("slug"), item["legacy_slug"]].compact.include?(requested_chapter)
      end

      if requested_chapter.present? && @current_chapter.nil?
        return redirect_to(posturacorretta_path(sezione: @current_section.fetch("id")), alert: "Questo capitolo è ancora in revisione.")
      end

      @selected_chapter = @current_chapter&.fetch("slug")
      @chapter_has_own_title = chapter_has_own_title?(@current_chapter)
      load_section_intro unless @current_chapter
      load_chapter_content
      load_related_contents
      render "posturacorrettastart/one_month"
    end

    private

    def load_home_index
      data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/guide/indice.yml"), permitted_classes: [], aliases: false) || {}
      @guide_editor = Current.user&.superadmin_user? || false
      @guide_tutor = current_user_posturacorretta_tutor?
      all_sections = data.fetch("sections", []).reject { |section| section["id"] == "percorso" }.map { |section| decorate_guide_section(section) }
      @home_sections = if @guide_editor
        all_sections
      elsif @guide_tutor
        tutor_accessible_sections(all_sections)
      else
        published_sections(all_sections)
      end
      @chapter_items = @home_sections.flat_map { |section| flatten_guide_items(section.fetch("items", [])) }
      @chapters = @chapter_items.map { |item| [item.fetch("slug"), item.fetch("title")] }
    end

    def decorate_guide_section(section)
      status = section.fetch("status", "draft")
      section.merge(
        "effective_status" => status,
        "items" => decorate_guide_items(section.fetch("items", []), status)
      )
    end

    def decorate_guide_items(items, inherited_status)
      items.map do |item|
        status = item.fetch("status", inherited_status)
        decorated = item.merge("effective_status" => status)
        decorated["children"] = decorate_guide_items(item.fetch("children", []), status) if item["type"] == "group"
        decorated
      end
    end

    def published_sections(sections)
      sections.filter_map do |section|
        next unless section["effective_status"] == "published"

        section.merge("items" => published_guide_items(section.fetch("items", [])))
      end
    end

    def current_user_posturacorretta_tutor?
      return false unless Current.user&.profile

      brand_node = Domain.find_by(hostname: "posturacorretta.org")&.node
      return false unless brand_node

      Current.user.role_assignments.where(
        role: :operator,
        role_operator: "tutor",
        context: brand_node
      ).exists?
    end

    def tutor_accessible_sections(sections)
      sections.filter_map do |section|
        public_items = section["effective_status"] == "published" ? published_guide_items(section.fetch("items", [])) : []
        tutor_items = section.fetch("items", []).select { |item| item["visibility"] == "internal_tutor" }
        visible_items = (public_items + tutor_items).uniq { |item| [item["type"], item["title"], item["slug"]] }
        next if visible_items.empty?

        section.merge("items" => visible_items)
      end
    end

    def published_guide_items(items)
      items.filter_map do |item|
        next unless item["effective_status"] == "published"

        if item["type"] == "group"
          children = published_guide_items(item.fetch("children", []))
          next if children.empty?
          item.merge("children" => children)
        else
          item
        end
      end
    end

    def load_home_intro
      data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/guide/home_intro.yml"), permitted_classes: [], aliases: false) || {}
      @home_intro_components = data.fetch("components", [])
      load_catalog
      @home_search_items = build_home_search_items
    end

    def build_home_search_items
      @catalog.flat_map do |category_key, category|
        category.fetch(:articles, []).map do |article|
          external = article[:url].present?
          {
            title: article[:title],
            meta: [category[:label], article[:item_type] == "course" ? "Corso" : article[:format].to_s.capitalize].compact_blank.join(" · "),
            href: external ? article[:url] : posturacorretta_articolo_path(article[:slug]),
            external: external,
            search: [
              article[:title], article[:excerpt], article[:subcategory], category[:label],
              article[:area], article[:paradigm], article[:methodologies], article[:zones],
              article[:author], article[:channel]
            ].flatten.compact.join(" ")
          }
        end
      end.uniq { |item| [item[:href], item[:title]] }
    end

    def flatten_guide_items(items)
      items.flat_map do |item|
        item["type"] == "group" ? flatten_guide_items(item.fetch("children", [])) : [item]
      end
    end

    def section_for_legacy_chapter(chapter)
      return "progetto" if chapter.to_s.match?(/\A(?:07|08|09|10|11)-/)
      "accademia"
    end

    def first_month_guide_request?
      return true if params[:sezione] == "primo_mese"

      FIRST_MONTH_BOOK_CHAPTERS.key?(params[:chapter].to_s) ||
        FIRST_MONTH_BOOK_CHAPTERS.key?(params[:capitolo].to_s)
    end

    def redirect_first_month_to_book
      requested_chapter = params[:capitolo].presence || params[:chapter]
      chapter = FIRST_MONTH_BOOK_CHAPTERS[requested_chapter] || "copertina"
      redirect_to book_chapter_path(book_slug: FIRST_MONTH_BOOK_SLUG, id: chapter), status: :moved_permanently
    end

    def redirect_percorso_integrato_docs
      legacy_doc = params[:capitolo].presence || params[:chapter]
      destination = PERCORSO_INTEGRATO_DOCS[legacy_doc]
      redirect_to(percorso_integrato_docs_path(doc: destination), status: :moved_permanently)
    end

    def chapter_has_own_title?(chapter)
      return false unless chapter
      return true unless chapter["type"] == "partial"

      chapter.fetch("source", "").include?("sections/03_percorso/")
    end

    def load_section_intro
      intro = @current_section["intro"]
      return unless intro&.fetch("type", nil) == "markdown"

      content_root = Rails.root.join("config/data/posturacorretta").cleanpath
      intro_path = content_root.join(intro.fetch("source")).cleanpath
      @section_intro = intro_path.read if intro_path.to_s.start_with?(content_root.to_s) && intro_path.file?
    end

    def load_chapter_content
      return unless @current_chapter

      if @current_chapter["type"] == "markdown"
        content_root = Rails.root.join("config/data/posturacorretta").cleanpath
        chapter_path = content_root.join(@current_chapter.fetch("source")).cleanpath
        @chapter_content = chapter_path.to_s.start_with?(content_root.to_s) && chapter_path.file? ? chapter_path.read : ""
      elsif @current_chapter["type"] == "partial"
        load_percorso_guide_data if @current_section["id"] == "percorso"
        @chapter_partial = @current_chapter.fetch("source")
      elsif @current_chapter["type"] == "vision"
        @vision_section = @current_chapter.fetch("section")
        load_first_month_vision
      end
    end

    def load_related_contents
      @related_contents = []
      references = Array(@current_chapter&.fetch("related_contents", []))
      return if references.empty?

      load_catalog unless defined?(@catalog) && @catalog.present?
      catalog_entries = @catalog.flat_map do |category_key, category|
        category.fetch(:articles, []).map do |article|
          article.merge(_category_key: category_key, _category_label: category[:label])
        end
      end

      @related_contents = references.filter_map do |reference|
        slug = reference.is_a?(Hash) ? reference["slug"] : reference
        category = reference["category"]&.to_sym if reference.is_a?(Hash)
        article = catalog_entries.find do |entry|
          entry[:slug] == slug && (category.blank? || entry[:_category_key] == category)
        end
        next unless article

        article.merge(_href: article[:url].presence || posturacorretta_articolo_path(article[:slug]))
      end
    end

    def load_percorso_guide_data
      data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/percorso/percorso.yml"), permitted_classes: [], aliases: false) || {}
      @paths = data.fetch("paths", {})
      @color_classes = data.fetch("colorClasses", {})
      @path_teams = data.fetch("pathTeams", {})
      @path_professionals = data.fetch("pathProfessionals", {})
      taxonomies = PosturacorrettaTaxonomies.load
      @scopes = taxonomies.fetch("scopes", {})
      @areas = taxonomies.fetch("areas", {})
    end

    def load_first_month_vision
      taxonomies = PosturacorrettaTaxonomies.load
      @scopes = taxonomies.fetch("scopes", {})
      @areas = taxonomies.fetch("areas", {})
      paradigms_path = Rails.root.join("config/data/posturacorretta/guide/02_progetto/01_paradigmi_e_matrice.md")
      return unless paradigms_path.file?

      @vision_paradigms, @vision_matrix = paradigms_path.read.split(/^# La Matrice\s*$/i, 2)
    end
  end
end
