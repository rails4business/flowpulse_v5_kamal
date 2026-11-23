module Posturacorretta
  class HomeJourney
    LEGACY_STATION_SLUGS = {
      "primo-incontro-kinesiologia-applicata" => "introduzione-alla-kinesiologia-applicata"
    }.freeze

    TAB_LABELS = {
      "online" => "Percorso online",
      "lezioni" => "Lezione",
      "prenota" => "Prenota"
    }.freeze

    STATIONS = [
      ["introduzione-al-percorso-integrato", "Inizia il percorso"],
      ["la-prima-settimana-con-posturacorretta", "Prima settimana"],
      ["introduzione-postura-e-fisiologia", "Postura e fisiologia"],
      ["area-massaggio-terapie-manuali-tecniche-corporee", "Area Recupero e terapie manuali"],
      ["igiene-posturale", "Igiene Posturale"],
      ["principi-di-fisioterapia", "Principi di Fisioterapia"],
      ["biomeccanica-comportamentale-gds", "Biomeccanica GDS"],
      ["principi-di-osteopatia", "Principi di Osteopatia"],
      ["introduzione-al-metodo-corpo-e-coscienza", "Corpo e Coscienza"],
      ["introduzione-alla-kinesiologia-applicata", "Kinesiologia Applicata"],
      ["altre-metodiche-posturali", "Altre metodiche"]
    ].map { |slug, title| { "slug" => slug, "title" => title } }.freeze

    LINE_STATIONS = {
      "inizia-con-posturacorretta" => STATIONS.first(3).pluck("slug"),
      "area-massaggio-terapie-manuali-tecniche-corporee" => STATIONS.drop(3).pluck("slug")
    }.freeze

    attr_reader :tab, :station, :resource

    # completed_chapters: { course_slug => [chapter_slug, ...] } dei capitoli completati dalla persona.
    def initialize(tappa:, tab:, risorsa: nil, completed_chapters: {})
      tappa = LEGACY_STATION_SLUGS.fetch(tappa, tappa)
      @station = STATIONS.find { |item| item.fetch("slug") == tappa } || STATIONS.first
      requested_tab = { "insegnanti" => "prenota", "centri" => "prenota" }.fetch(tab.to_s, tab.to_s)
      @tab = requested_tab.presence_in(tabs.keys) || tabs.keys.first || "online"
      @resource = risorsa.to_s.presence
      @completed_chapters = completed_chapters
    end

    def tabs
      data = course_data
      return { "online" => TAB_LABELS.fetch("online") } if data.blank?

      {}.tap do |available|
        available["online"] = TAB_LABELS.fetch("online") if data[:course].present?
        available["lezioni"] = TAB_LABELS.fetch("lezioni") if Array(data[:program_lessons]).any?
        available["prenota"] = TAB_LABELS.fetch("prenota") if Array(data[:teachers]).any? || Array(data[:centres]).any?
      end
    end
    def line_node
      slug = LINE_STATIONS.find { |_line_slug, station_slugs| station_slugs.include?(station.fetch("slug")) }&.first
      Node.find_by(slug:, view_type: "course_line") || Node.find_by(slug: "inizia-con-posturacorretta")
    end

    def line
      node = line_node
      return { "slug" => "inizia-con-posturacorretta", "title" => "Inizia con PosturaCorretta", "area" => "Introduzione" } unless node

      { "slug" => node.slug, "title" => node.title, "area" => node.content_type.presence || "Percorso" }
    end

    def stations
      slugs = LINE_STATIONS.fetch(line.fetch("slug"), STATIONS.pluck("slug"))
      STATIONS.select { |item| slugs.include?(item.fetch("slug")) }
    end

    def station_number = stations.index(station) + 1

    def previous_station
      index = STATIONS.index(station)
      STATIONS[index - 1] if index&.positive?
    end

    def next_station
      index = STATIONS.index(station)
      STATIONS[index + 1] if index && index < STATIONS.size - 1
    end

    def station_for_node(node)
      STATIONS.find { |item| item.fetch("slug") == node.slug }
    end

    # Metà online del pallino: tutti i capitoli del corso della tappa sono completati.
    def online_completed?(item)
      progress = online_progress(item)
      progress[:total].positive? && progress[:done] == progress[:total]
    end

    def online_progress(item)
      data = station_data(item)
      chapters = Array(data&.fetch(:chapters, nil)).map { |chapter| chapter.fetch("slug") }
      return { done: 0, total: 0 } if chapters.empty?

      done = Array(@completed_chapters[data.fetch(:course)["slug"]])
      { done: chapters.count { |slug| done.include?(slug) }, total: chapters.size }
    end

    def course_data
      station_data(station)
    end

    def station_available?(item)
      data = station_data(item)
      return false if data.blank?

      case tab
      when "lezioni"
        data.fetch(:program_lessons, []).any?
      when "prenota"
        resource_available?([*data.fetch(:teachers, []), *data.fetch(:centres, [])])
      else
        data[:course].present?
      end
    end

    def resource_options
      return [] unless tab == "prenota"

      STATIONS.flat_map { |item| [*Array(station_data(item)&.fetch(:teachers, [])), *Array(station_data(item)&.fetch(:centres, []))] }
        .uniq { |item| item.fetch("slug") }
        .sort_by { |item| item.fetch("name").downcase }
    end

    def teachers
      filter_resources(course_data&.fetch(:teachers, []))
    end

    def centres
      filter_resources(course_data&.fetch(:centres, []))
    end

    # Scheda del percorso: i corsi della linea in ordine, ciascuno con le sue lezioni.
    # Le lezioni che seguono una lezione senza corso proprio restano nel corso precedente.
    SheetCourse = Data.define(:node, :station, :lessons)

    def sheet_courses(_legacy_line_slug = nil)
      return [] unless line_node

      line_node.ordered_line_nodes.map do |course_node|
        lessons = course_node.self_and_descendants.where(view_type: "course_lesson").order(:depth, :position, :id).to_a
        course = SheetCourse.new(node: course_node, station: nil, lessons: lessons)
        slugs = [course.node.slug, *course.lessons.map(&:slug)]
        course.with(station: STATIONS.find { |item| slugs.include?(item.fetch("slug")) })
      end
    end

    def station_data(item)
      @station_data ||= {}
      @station_data[item.fetch("slug")] ||= HomeCourseCatalog.fetch(item.fetch("slug"))
    rescue KeyError, ArgumentError
      nil
    end

    private

      def resource_available?(items)
        return items.any? if resource.blank?

        items.any? { |item| item.fetch("slug") == resource }
      end

      def filter_resources(items)
        items = Array(items)
        resource.present? ? items.select { |item| item.fetch("slug") == resource } : items
      end
  end
end
