class MarkposturaHome
  DATA_PATH = Rails.root.join("config/data/markpostura/home.json").freeze
  WEEKS_PATH = Rails.root.join("config/data/markpostura/settimane").freeze

  class << self
    def load
      data = JSON.parse(DATA_PATH.read)
      data.fetch("week_plan")["weeks"] = load_weeks(data.fetch("week_plan").fetch("spaces"))
      data
    end

    def timeline(include_private: false)
      events = DomainEventCatalog.for_organizer("markpostura", include_drafts: include_private).map do |event|
        event.merge("timeline_type" => "event", "timeline_date" => event["event_date"], "timeline_label" => "Evento")
      end
      contents = DomainContentCatalog.for_author("markpostura", include_scheduled: include_private).map do |content|
        content.merge("timeline_type" => "content", "timeline_date" => content["publication_date"], "timeline_label" => "Contenuto", "canonical_domain_name" => content["domain_name"])
      end

      (events + contents).sort_by do |item|
        date = item["timeline_date"]
        if date.blank?
          [2, 0, item.fetch("title", "")]
        elsif date >= Date.current
          [0, date.jd, item.fetch("title", "")]
        else
          [1, -date.jd, item.fetch("title", "")]
        end
      end
    end

    def week_source(week_key)
      return unless week_key.to_s.match?(/\A\d{4}-W\d{2}\z/)

      path = WEEKS_PATH.join("#{week_key}.yml")
      return unless path.file?

      { path: path, content: path.read }
    end

    private

    def load_weeks(spaces)
      allowed_spaces = spaces.map { |space| space.fetch("slug") }

      Dir.glob(WEEKS_PATH.join("*.yml")).sort.to_h do |path|
        week = YAML.safe_load_file(path, aliases: false) || {}
        key = week.fetch("week")
        entries = Array(week["entries"])

        entries.each do |entry|
          next if allowed_spaces.include?(entry["space"])

          raise ArgumentError, "Spazio Week Plan non valido: #{entry['space']} in #{path}"
        end

        [key, week]
      end
    end
  end
end
