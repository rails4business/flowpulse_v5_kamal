require "yaml"

module Editorial
  class SiteRepository
    ROOT = Rails.root.join("config/data/sites").freeze
    KEY_PATTERN = /\A[a-z0-9]+(?:[a-z0-9_-]*[a-z0-9])?\z/

    Site = Data.define(:key, :root, :configuration, :mounts_configuration) do
      def site
        configuration.fetch("site")
      end

      def mounts
        Array(mounts_configuration["mounts"])
      end

      def redirects
        Array(mounts_configuration["redirects"])
      end

      def mount(key)
        mounts.find { |candidate| candidate["key"] == key.to_s }
      end

      def mount_for_path(path)
        mounts.find { |candidate| candidate["path"] == path }
      end
    end

    def initialize(root: ROOT)
      @root = Pathname(root)
    end

    def keys
      return [] unless @root.directory?

      @root.children.select(&:directory?).map { |path| path.basename.to_s }.select { |key| valid_key?(key) }.sort
    end

    def load(site_key)
      key = normalize_key!(site_key)
      site_root = confined_directory!(key)

      Site.new(
        key: key,
        root: site_root,
        configuration: load_yaml(site_root.join("site.yml")),
        mounts_configuration: load_yaml(site_root.join("mounts.yml"))
      )
    end

    def page(site, page_key)
      key = normalize_key!(page_key)
      load_yaml(confined_file!(site.root.join("pages"), "#{key}.yml"))
    end

    def page_keys(site)
      directory = site.root.join("pages")
      return [] unless directory.directory?

      directory.glob("*.yml").map { |path| path.basename(".yml").to_s }.select { |key| valid_key?(key) }.sort
    end

    private

    def valid_key?(key)
      key.to_s.match?(KEY_PATTERN)
    end

    def normalize_key!(key)
      normalized = key.to_s
      raise InvalidKeyError, "Chiave editoriale non valida: #{normalized.inspect}" unless valid_key?(normalized)

      normalized
    end

    def confined_directory!(key)
      path = @root.join(key).cleanpath
      raise SourceNotFoundError, "Site non trovato: #{key}" unless path.directory? && inside?(path, @root)

      path
    end

    def confined_file!(directory, filename)
      path = directory.join(filename).cleanpath
      raise SourceNotFoundError, "Sorgente editoriale non trovata: #{filename}" unless path.file? && inside?(path, directory)

      path
    end

    def inside?(path, root)
      expanded_path = path.expand_path.to_s
      expanded_root = root.expand_path.to_s
      expanded_path == expanded_root || expanded_path.start_with?("#{expanded_root}/")
    end

    def load_yaml(path)
      YAML.safe_load_file(path, permitted_classes: [], permitted_symbols: [], aliases: false) || {}
    rescue Psych::Exception => error
      raise InvalidSourceError, "YAML non valido in #{path.relative_path_from(Rails.root)}: #{error.message}"
    end
  end
end
