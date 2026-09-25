class FlowpulseDevelopmentRepository
  ROOT = Rails.root.join("config/data/brands/flowpulse/development").freeze
  INDEX_PATH = ROOT.join("index.yml").freeze
  KEY_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  STATUSES = %w[proposed approved in_progress verified deployed paused].freeze

  def entries
    data.fetch("entries", []).map { |entry| decorate(entry) }
      .sort_by { |entry| [entry.fetch("updated_on_value"), entry.fetch("slug")] }
      .reverse
  end

  def find(slug)
    normalized_slug = normalize_key!(slug)
    entries.find { |entry| entry.fetch("slug") == normalized_slug }
  end

  def brand_directory
    @brand_directory ||= ChangelogRepository.catalog.transform_values do |brand|
      brand.slice("key", "label", "canonical_host", "public_path")
    end
  end

  private

    def data
      @data ||= begin
        parsed = YAML.safe_load_file(INDEX_PATH, permitted_classes: [], aliases: false) || {}
        parsed.fetch("entries", []).each { |entry| validate!(entry) }
        parsed
      end
    end

    def validate!(entry)
      normalize_key!(entry.fetch("slug"))
      owner_brand = normalize_key!(entry.fetch("owner_brand"))
      raise ArgumentError, "Brand della scheda non configurato: #{owner_brand}" unless brand_directory.key?(owner_brand)

      status = entry.fetch("status")
      raise ArgumentError, "Stato della scheda non valido: #{status}" unless STATUSES.include?(status)

      Date.iso8601(entry.fetch("started_on"))
      Date.iso8601(entry.fetch("updated_on"))
      Array(entry.fetch("tags", [])).each { |tag| normalize_key!(tag) }
      if entry["changelog"].present?
        changelog_brand = normalize_key!(entry.fetch("changelog").fetch("brand"))
        normalize_key!(entry.fetch("changelog").fetch("slug"))
        raise ArgumentError, "Brand changelog non configurato: #{changelog_brand}" unless brand_directory.key?(changelog_brand)
      end
      confined_source(entry.fetch("source"))
    end

    def decorate(entry)
      source = confined_source(entry.fetch("source"))
      brand = brand_directory.fetch(entry.fetch("owner_brand"))
      entry.merge(
        "tags" => Array(entry.fetch("tags", [])),
        "owner_brand_label" => brand.fetch("label"),
        "started_on_value" => Date.iso8601(entry.fetch("started_on")),
        "updated_on_value" => Date.iso8601(entry.fetch("updated_on")),
        "body" => source.read,
        "source_path" => source.relative_path_from(Rails.root).to_s
      )
    end

    def confined_source(source)
      path = ROOT.join(source).cleanpath
      raise ArgumentError, "Sorgente sviluppo fuori dalla cartella Flowpulse" unless path.to_s.start_with?("#{ROOT}/")
      raise ArgumentError, "Sorgente sviluppo mancante: #{source}" unless path.file?

      path
    end

    def normalize_key!(value)
      key = value.to_s
      raise ArgumentError, "Chiave sviluppo non valida: #{key.inspect}" unless key.match?(KEY_PATTERN)

      key
    end
end
