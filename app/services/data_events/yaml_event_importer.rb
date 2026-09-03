module DataEvents
  class YamlEventImporter
    attr_reader :domain_key, :domain, :creator, :source_path

    def initialize(domain_key:, domain: nil, creator: nil, source_path: nil)
      @domain_key = domain_key.to_s
      @domain = domain || find_domain!
      @creator = creator || find_creator!
      @source_path = Pathname(source_path || Rails.root.join("config/data", @domain_key, "eventi/eventi.yml"))
    end

    def call
      raw = YAML.safe_load_file(source_path, permitted_classes: [], aliases: false) || {}
      defaults = raw.fetch("defaults", {})
      imported = raw.fetch("events", []).map { |event| import_event(defaults.merge(event)) }

      { events: imported, places: import_catalog_places(raw.fetch("places", [])) }
    end

    private

      def import_event(event)
        slug = event["slug"].presence || [event["date"], event["title"]].compact.join("-").parameterize
        date = parse_date(event["date"])
        status = normalized_status(event)
        place = find_or_create_event_place(event)

        DataEvent.transaction do
          root = find_by_source("yaml_event_slug", slug) || DataEvent.new
          root.assign_attributes(
            title: event.fetch("title"),
            description: event["description"],
            classification: "event",
            node_kind: "root",
            domain: domain,
            created_by_profile: creator,
            responsible_profile: creator,
            place: place,
            active_from: date,
            active_until: date,
            status: status,
            visibility: status == "draft" ? "private" : "public",
            published_at: status == "draft" ? nil : (root.published_at || Time.current),
            registration_status: normalized_registration_status(event),
            registration_mode: normalized_registration_mode(event),
            bookable: event["registration_mode"].to_s == "required",
            booking_mode: event["registration_mode"].to_s == "required" ? "parent" : "none",
            booking_notes: event["waText"],
            metadata: editorial_metadata(event, slug)
          )
          root.save!
          sync_day_and_program(root, event, date)
          root
        end
      end

      def sync_day_and_program(root, event, date)
        return unless date

        day = root.children.find_by(node_kind: "day") || root.children.build
        day.assign_attributes(
          title: event["formattedDate"].presence || I18n.l(date, format: :long),
          classification: "event",
          node_kind: "day",
          domain: domain,
          created_by_profile: creator,
          starts_at: Time.zone.local(date.year, date.month, date.day),
          all_day: true,
          status: root.status,
          visibility: root.visibility,
          published_at: root.published_at,
          registration_status: root.registration_status,
          registration_mode: root.registration_mode,
          position: 1,
          metadata: { "yaml_event_slug" => root.metadata.fetch("yaml_event_slug"), "source_kind" => "event_day" }
        )
        day.save!
        sync_program_sessions(day, event, date)
      end

      def sync_program_sessions(day, event, date)
        program = Array(event["program"]).presence || [event.fetch("title")]
        parsed = program.map.with_index { |line, index| parse_program_line(line, date, index) }

        parsed.each_with_index do |item, index|
          source_key = "#{day.metadata.fetch('yaml_event_slug')}:#{index + 1}"
          session = day.children.where(node_kind: "session").find_by("metadata @> ?", { "yaml_program_key" => source_key }.to_json) || day.children.build
          next_start = parsed[index + 1]&.fetch(:starts_at)
          ends_at = next_start if item.fetch(:starts_at) && next_start
          session.assign_attributes(
            title: item.fetch(:title),
            classification: "event",
            node_kind: "session",
            domain: domain,
            created_by_profile: creator,
            starts_at: item.fetch(:starts_at),
            ends_at: ends_at,
            status: day.status,
            visibility: day.visibility,
            published_at: day.published_at,
            registration_status: day.registration_status,
            registration_mode: day.registration_mode,
            position: index + 1,
            metadata: { "yaml_program_key" => source_key, "source_kind" => "program_item" }
          )
          session.save!
        end
      end

      def parse_program_line(line, date, index)
        text = line.to_s.strip
        match = text.match(/\A(?<hour>\d{1,2}):(?<minute>\d{2})\s*[—–-]\s*(?<title>.+)\z/)
        return { title: text.sub(/\A\?\s*[—–-]\s*/, ""), starts_at: nil } unless match

        {
          title: match[:title],
          starts_at: Time.zone.local(date.year, date.month, date.day, match[:hour].to_i, match[:minute].to_i)
        }
      end

      def editorial_metadata(event, slug)
        {
          "source" => "yaml",
          "source_path" => source_path.relative_path_from(Rails.root).to_s,
          "yaml_event_id" => event["id"],
          "yaml_event_slug" => slug,
          "image" => event["image"],
          "ambiti" => Array(event["ambiti"]),
          "aree" => Array(event["aree"]),
          "paradigmi" => Array(event["paradigmi"]),
          "professional_slugs" => Array(event["professional_slugs"]),
          "teachers" => Array(event["teachers"]),
          "projects" => Array(event["projects"]),
          "wa_text" => event["waText"],
          "legacy_type" => event["type"]
        }.compact
      end

      def find_or_create_event_place(event)
        key = event["place_slug"].presence || event["locationKey"].presence
        return if key.blank? || key == "da-definire"

        existing = Brands::Impegno::Place.where(domain: domain).find_by("metadata @> ?", { "yaml_place_key" => key }.to_json)
        return existing if existing

        Brands::Impegno::Place.create!(
          profile: creator,
          domain: domain,
          name: event["location"].presence || key.humanize,
          kind: "event_space",
          scope: "domain",
          approval_status: "approved",
          metadata: { "yaml_place_key" => key, "source" => "yaml_event" }
        )
      end

      def import_catalog_places(places)
        places.map do |place|
          key = place.fetch("key")
          record = Brands::Impegno::Place.where(domain: domain).find_by("metadata @> ?", { "yaml_place_key" => key }.to_json)
          record ||= Brands::Impegno::Place.new(profile: creator, domain: domain)
          record.assign_attributes(
            name: place.fetch("name"),
            notes: place["description"],
            kind: "event_space",
            scope: "domain",
            approval_status: "approved",
            metadata: { "yaml_place_key" => key, "source" => "yaml_catalog", "image" => place["image"] }.compact
          )
          record.save!
          record
        end
      end

      def find_by_source(key, value)
        DataEvent.where(domain: domain, node_kind: "root").find_by("metadata @> ?", { key => value }.to_json)
      end

      def normalized_status(event)
        return "completed" if event["type"] == "past"

        status = event.fetch("event_status", event.fetch("status", "confirmed")).to_s
        DataEvent::STATUSES.include?(status) ? status : "organizing"
      end

      def normalized_registration_status(event)
        value = event.fetch("registration_status", "pending").to_s
        DataEvent::REGISTRATION_STATUSES.include?(value) ? value : "pending"
      end

      def normalized_registration_mode(event)
        value = event.fetch("registration_mode", "none").to_s
        DataEvent::REGISTRATION_MODES.include?(value) ? value : "pending"
      end

      def parse_date(value)
        Date.iso8601(value.to_s) if value.present?
      rescue ArgumentError
        nil
      end

      def find_domain!
        hostname = DomainEventCatalog::DOMAIN_SETTINGS.dig(domain_key, "host") || domain_key
        Domain.find_by!(hostname: hostname)
      end

      def find_creator!
        Profile.find_by!(username: "markpostura")
      end
  end
end
