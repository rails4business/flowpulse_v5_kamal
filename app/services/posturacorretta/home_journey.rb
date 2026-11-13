module Posturacorretta
  class HomeJourney
    LEGACY_STATION_SLUGS = {
      "primo-incontro-kinesiologia-applicata" => "introduzione-alla-kinesiologia-applicata"
    }.freeze

    TABS = {
      "online" => "Percorso online",
      "lezioni" => "Programma lezioni",
      "centri" => "Centri",
      "insegnanti" => "Insegnanti"
    }.freeze

    STATIONS = [
      ["introduzione-al-percorso-integrato", "Introduzione al Percorso Integrato"],
      ["la-prima-settimana-con-posturacorretta", "Prima settimana"],
      ["introduzione-postura-e-fisiologia", "Postura e fisiologia"],
      ["area-massaggio-terapie-manuali-tecniche-corporee", "Area Massaggio e recupero"],
      ["igiene-posturale", "Igiene Posturale"],
      ["principi-di-fisioterapia", "Principi di Fisioterapia"],
      ["biomeccanica-comportamentale-gds", "Biomeccanica GDS"],
      ["principi-di-osteopatia", "Principi di Osteopatia"],
      ["introduzione-al-metodo-corpo-e-coscienza", "Corpo e Coscienza"],
      ["introduzione-alla-kinesiologia-applicata", "Kinesiologia Applicata"],
      ["altre-metodiche-posturali", "Altre metodiche"]
    ].map { |slug, title| { "slug" => slug, "title" => title } }.freeze

    attr_reader :tab, :station, :resource

    def initialize(tappa:, tab:, risorsa: nil)
      tappa = LEGACY_STATION_SLUGS.fetch(tappa, tappa)
      @station = STATIONS.find { |item| item.fetch("slug") == tappa } || STATIONS.first
      @tab = tab.to_s.presence_in(TABS.keys) || "online"
      @resource = risorsa.to_s.presence
    end

    def tabs = TABS
    def stations = STATIONS

    def course_data
      station_data(station)
    end

    def station_available?(item)
      data = station_data(item)
      return false if data.blank?

      case tab
      when "lezioni"
        data.fetch(:program_lessons, []).any?
      when "centri"
        resource_available?(data.fetch(:centres, []))
      when "insegnanti"
        resource_available?(data.fetch(:teachers, []))
      else
        data[:course].present?
      end
    end

    def resource_options
      return [] unless %w[centri insegnanti].include?(tab)

      key = tab == "centri" ? :centres : :teachers
      STATIONS.flat_map { |item| Array(station_data(item)&.fetch(key, [])) }
        .uniq { |item| item.fetch("slug") }
        .sort_by { |item| item.fetch("name").downcase }
    end

    def filtered_resources
      key = tab == "centri" ? :centres : :teachers
      items = Array(course_data&.fetch(key, []))
      resource.present? ? items.select { |item| item.fetch("slug") == resource } : items
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
  end
end
