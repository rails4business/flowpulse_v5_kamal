require "yaml"

module BrandEditorial
  # Registro neutro del materiale editoriale posseduto da un Brand.
  #
  # Non sostituisce ancora i repository esistenti: permette di dichiarare le
  # sorgenti correnti, distinguere ciò che è pubblico dalle bozze e spostare un
  # blocco alla volta senza perdere i collegamenti pubblici già attivi.
  class Repository
    ROOT = Rails.root.join("config/data/brands").freeze
    KEY_PATTERN = /\A[a-z0-9]+(?:[a-z0-9_-]*[a-z0-9])?\z/
    STATUSES = %w[draft scheduled published archived].freeze
    VISIBILITIES = %w[private internal public].freeze

    Brand = Data.define(:key, :root, :configuration) do
      def editorial
        configuration.fetch("editorial")
      end

      def entries
        Array(editorial["entries"])
      end
    end

    def initialize(root: ROOT)
      @root = Pathname(root)
    end

    def keys
      return [] unless root.directory?

      root.children.select(&:directory?).map { |path| path.basename.to_s }.select { |key| valid_key?(key) }.sort
    end

    def load(brand_key)
      key = normalize_key!(brand_key)
      brand_root = confined_directory!(key)
      configuration = load_yaml(brand_root.join("editorial.yml"))
      validate_configuration!(configuration, key)

      Brand.new(key: key, root: brand_root, configuration: configuration)
    end

    # Per il pubblico restituisce soltanto materiale pubblicato e pubblico.
    # Il back-office può chiedere anche bozze, programmati e archiviati.
    def entries(brand_key, include_non_public: false)
      entries = load(brand_key).entries.map(&:deep_stringify_keys)
      return entries if include_non_public

      entries.select { |entry| entry.fetch("status") == "published" && entry.fetch("visibility") == "public" }
    end

    # Risolve una sorgente solo sotto config/data: nessun percorso assoluto o
    # traversal può essere introdotto da YAML.
    def source_path(entry)
      source = entry.to_h.deep_stringify_keys.fetch("source")
      path = Rails.root.join("config/data", source).cleanpath
      data_root = Rails.root.join("config/data").expand_path
      expanded = path.expand_path
      raise Editorial::InvalidSourceError, "Sorgente editoriale fuori da config/data: #{source}" unless expanded.to_s.start_with?("#{data_root}/")
      raise Editorial::SourceNotFoundError, "Sorgente editoriale non trovata: #{source}" unless expanded.exist?

      expanded
    end

    private

    attr_reader :root

    def valid_key?(key)
      key.to_s.match?(KEY_PATTERN)
    end

    def normalize_key!(key)
      normalized = key.to_s
      raise Editorial::InvalidKeyError, "Chiave Brand editoriale non valida: #{normalized.inspect}" unless valid_key?(normalized)

      normalized
    end

    def confined_directory!(key)
      path = root.join(key).cleanpath
      raise Editorial::SourceNotFoundError, "Brand editoriale non trovato: #{key}" unless path.directory? && inside?(path, root)

      path
    end

    def inside?(path, container)
      expanded_path = path.expand_path.to_s
      expanded_container = container.expand_path.to_s
      expanded_path == expanded_container || expanded_path.start_with?("#{expanded_container}/")
    end

    def load_yaml(path)
      YAML.safe_load_file(path, permitted_classes: [], permitted_symbols: [], aliases: false) || {}
    rescue Psych::Exception => error
      raise Editorial::InvalidSourceError, "YAML non valido in #{path.relative_path_from(Rails.root)}: #{error.message}"
    end

    def validate_configuration!(configuration, key)
      editorial = configuration["editorial"]
      raise Editorial::InvalidSourceError, "#{key}: editorial.yml deve contenere editorial" unless editorial.is_a?(Hash)
      raise Editorial::InvalidSourceError, "#{key}: owner_node_slug obbligatorio" if editorial["owner_node_slug"].blank?
      raise Editorial::InvalidSourceError, "#{key}: entries deve essere un elenco" unless editorial["entries"].is_a?(Array)

      identifiers = editorial["entries"].map { |entry| entry.is_a?(Hash) ? entry["id"] : nil }
      raise Editorial::InvalidSourceError, "#{key}: entry senza id" if identifiers.any?(&:blank?)
      duplicates = identifiers.tally.select { |_id, count| count > 1 }.keys
      raise Editorial::InvalidSourceError, "#{key}: id duplicati: #{duplicates.join(', ')}" if duplicates.any?

      editorial["entries"].each do |entry|
        raise Editorial::InvalidSourceError, "#{key}: entry non valida" unless entry.is_a?(Hash)

        %w[id kind source status visibility].each do |field|
          raise Editorial::InvalidSourceError, "#{key}: #{entry['id'] || 'entry'} senza #{field}" if entry[field].blank?
        end
        raise Editorial::InvalidSourceError, "#{key}: status non valido: #{entry['status']}" unless entry["status"].in?(STATUSES)
        raise Editorial::InvalidSourceError, "#{key}: visibility non valida: #{entry['visibility']}" unless entry["visibility"].in?(VISIBILITIES)

        source_path(entry)
      end
    end
  end
end
