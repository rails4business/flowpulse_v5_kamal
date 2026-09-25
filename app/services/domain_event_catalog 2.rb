class DomainEventCatalog
  EVENT_ROOT = Rails.root.join("config/data").freeze

  DOMAIN_SETTINGS = {
    "posturacorretta" => {
      "name" => "PosturaCorretta",
      "host" => "posturacorretta.org",
      "events_path" => "/posturacorretta/eventi"
    },
    "markpostura" => {
      "name" => "Mark Postura",
      "host" => "markpostura.it",
      "events_path" => "/markpostura/eventi"
    },
    "flowpulse" => {
      "name" => "Flowpulse",
      "host" => "flowpulse.net",
      "events_path" => "/eventi"
    }
  }.freeze

  class << self
    def for_domain(domain_key, include_drafts: false)
      all(include_drafts:).select { |event| event.fetch("canonical_domain") == domain_key.to_s }
    end

    def for_project(project_key, include_drafts: false)
      all(include_drafts:).select { |event| event.fetch("projects").include?(project_key.to_s) }
    end

    def for_organizer(username, include_drafts: false)
      normalized_username = normalize_username(username)
      all(include_drafts:).select do |event|
        event.fetch("organizer_usernames").include?(normalized_username)
      end
    end

    def all(include_drafts: false)
      event_paths.flat_map { |path| load_events(path, include_drafts:) }
                 .uniq { |event| [event.fetch("canonical_domain"), event.fetch("slug")] }
    end

    private

      def event_paths
        Dir.glob(EVENT_ROOT.join("*/eventi/eventi.yml")).sort
      end

      def load_events(path, include_drafts:)
        source_domain = Pathname(path).relative_path_from(EVENT_ROOT).each_filename.first
        raw = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
        defaults = raw.fetch("defaults", {})

        raw.fetch("events", []).filter_map do |event|
          decorate_event(defaults.merge(event), source_domain, include_drafts:)
        end
      rescue Psych::SyntaxError => error
        Rails.logger.error("Catalogo eventi non valido #{path}: #{error.message}")
        []
      end

      def decorate_event(event, source_domain, include_drafts:)
        return unless event.is_a?(Hash)

        event_status = event.fetch("event_status", event.fetch("status", "confirmed")).to_s
        return if event_status == "draft" && !include_drafts

        canonical_domain = event.fetch("canonical_domain", source_domain).to_s
        projects = Array(event["projects"]).map(&:to_s)
        projects << canonical_domain if projects.empty?
        projects << "giardino-del-corpo" if Array(event["ambiti"]).map(&:to_s).include?("giardino")
        projects = projects.reject(&:blank?).uniq
        organizers = Array(event["organizer_usernames"]).map { |username| normalize_username(username) }.reject(&:blank?).uniq
        event_date = parse_date(event["date"])
        settings = DOMAIN_SETTINGS.fetch(canonical_domain, default_domain_settings(canonical_domain))
        slug = event["slug"].presence || event_slug(event)

        event.merge(
          "slug" => slug,
          "source_domain" => source_domain,
          "canonical_domain" => canonical_domain,
          "canonical_domain_name" => settings.fetch("name"),
          "projects" => projects,
          "organizer_usernames" => organizers,
          "event_date" => event_date,
          "event_status" => event_status,
          "url" => "https://#{settings.fetch('host')}#{settings.fetch('events_path')}"
        )
      end

      def event_slug(event)
        [event["date"], event["title"]].compact.join("-").parameterize.presence || "evento-#{event.fetch('id', 'senza-id')}"
      end

      def normalize_username(username)
        username.to_s.delete_prefix("@").strip.downcase
      end

      def parse_date(value)
        Date.iso8601(value.to_s) if value.present?
      rescue ArgumentError
        nil
      end

      def default_domain_settings(domain_key)
        {
          "name" => domain_key.to_s.humanize,
          "host" => domain_key.to_s,
          "events_path" => "/eventi"
        }
      end
  end
end
