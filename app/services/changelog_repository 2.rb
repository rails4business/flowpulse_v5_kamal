class ChangelogRepository
  ROOT = Rails.root.join("config/data/brands").freeze
  KEY_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  class << self
    def catalog(root: ROOT)
      Pathname(root).glob("*/changelog/index.yml").each_with_object({}) do |index_path, brands|
        parsed = load_index(index_path)
        brand = parsed.fetch("brand")
        key = normalize_key!(brand.fetch("key"))
        raise ArgumentError, "Brand changelog duplicato: #{key}" if brands.key?(key)

        entries = parsed.fetch("entries", [])
        brands[key] = brand.merge(
          "key" => key,
          "root" => index_path.dirname,
          "entry_count" => entries.count { |entry| entry.fetch("visibility", "public") != "internal" }
        )
      end.sort.to_h
    end

    def for_host(host, root: ROOT)
      normalized_host = Domain.normalize_host(host)
      key, = catalog(root:).find do |_brand_key, brand|
        Array(brand.fetch("hosts", [])).map { |candidate| Domain.normalize_host(candidate) }.include?(normalized_host)
      end
      new(brand: key || "flowpulse", root:)
    end

    def normalize_key!(value)
      key = value.to_s
      raise ArgumentError, "Chiave changelog non valida: #{key.inspect}" unless key.match?(KEY_PATTERN)

      key
    end

    private

      def load_index(path)
        YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
      end
  end

  attr_reader :brand_key

  def initialize(brand:, root: ROOT)
    @root = Pathname(root)
    @brand_key = self.class.normalize_key!(brand)
    @brand_root = @root.join(@brand_key, "changelog").cleanpath
    raise ArgumentError, "Changelog del Brand non trovato: #{@brand_key}" unless @brand_root.join("index.yml").file?
  end

  def brand
    data.fetch("brand")
  end

  def entries(include_internal: false)
    data.fetch("entries", []).filter_map do |entry|
      next if entry.fetch("visibility", "public") == "internal" && !include_internal

      decorate(entry)
    end.sort_by { |entry| [entry.fetch("date"), entry.fetch("slug")] }.reverse
  end

  def find(slug, include_internal: false)
    normalized_slug = self.class.normalize_key!(slug)
    entries(include_internal:).find { |entry| entry.fetch("slug") == normalized_slug }
  end

  private

    def data
      @data ||= begin
        parsed = self.class.send(:load_index, @brand_root.join("index.yml"))
        configured_key = self.class.normalize_key!(parsed.fetch("brand").fetch("key"))
        raise ArgumentError, "La cartella #{@brand_key} dichiara il Brand #{configured_key}" unless configured_key == @brand_key

        parsed.fetch("entries", []).each do |entry|
          self.class.normalize_key!(entry.fetch("slug"))
          Date.iso8601(entry.fetch("date"))
          Array(entry.fetch("tags", [])).each { |tag| self.class.normalize_key!(tag) }
        end
        parsed
      end
    end

    def decorate(entry)
      source = confined_source(entry.fetch("source"))
      entry.merge(
        "tags" => Array(entry.fetch("tags", [])),
        "date_value" => Date.iso8601(entry.fetch("date")),
        "body" => source.read,
        "source_path" => source.relative_path_from(Rails.root).to_s
      )
    end

    def confined_source(source)
      path = @brand_root.join(source).cleanpath
      raise ArgumentError, "Sorgente changelog fuori dalla cartella del Brand" unless path.to_s.start_with?("#{@brand_root}/")
      raise ArgumentError, "Sorgente changelog mancante: #{source}" unless path.file?

      path
    end
end
