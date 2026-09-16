module Editorial
  class Validator
    Result = Data.define(:errors, :warnings, :counts) do
      def valid?
        errors.empty?
      end
    end

    STATUSES = %w[draft published archived].freeze
    VISIBILITIES = %w[public superadmin].freeze
    SCHEMA_VERSION = 1
    PATH_PATTERN = %r{\A/(?:[a-z0-9]+(?:-[a-z0-9]+)*/?)*\z}

    def initialize(repository: SiteRepository.new)
      @repository = repository
    end

    def validate(site_key = nil)
      @errors = []
      @warnings = []
      @counts = { sites: 0, pages: 0, mounts: 0 }

      keys = site_key.present? ? [site_key.to_s] : @repository.keys
      keys.each { |key| validate_site(key) }

      Result.new(errors: @errors.freeze, warnings: @warnings.freeze, counts: @counts.freeze)
    end

    private

    def validate_site(key)
      site = @repository.load(key)
      @counts[:sites] += 1
      config = site.configuration
      settings = config["site"]

      schema_version(config, "site.yml", key)
      schema_version(site.mounts_configuration, "mounts.yml", key)
      error(key, "mounts.yml site_key non coincide con la cartella") unless site.mounts_configuration["site_key"] == key
      error(key, "site.yml deve contenere site") unless settings.is_a?(Hash)
      return unless settings.is_a?(Hash)

      error(key, "site.key deve coincidere con la cartella") unless settings["key"] == key
      required(settings, %w[key node_slug locale theme entrypoint], "site", key)
      error(key, "tema non registrato: #{settings['theme']}") unless ThemeRegistry.registered?(settings["theme"])

      mount_keys = site.mounts.filter_map { |mount| mount["key"] }
      entrypoint = settings.dig("entrypoint", "mount")
      error(key, "entrypoint.mount non esiste: #{entrypoint}") unless mount_keys.include?(entrypoint)
      duplicates(mount_keys).each { |value| error(key, "Mount duplicato: #{value}") }
      duplicates(site.mounts.filter_map { |mount| mount["path"] }).each { |value| error(key, "Path duplicato: #{value}") }

      site.mounts.each { |mount| validate_mount(site, mount) }
      mounted_pages = site.mounts.filter_map { |mount| mount.dig("resource", "key") }.uniq
      @repository.page_keys(site).each do |page_key|
        validate_page(site, page_key, mounted: mounted_pages.include?(page_key))
      end
      validate_redirects(site)
    rescue Error => exception
      error(key, exception.message)
    end

    def validate_mount(site, mount)
      @counts[:mounts] += 1
      required(mount, %w[key path resource], "mount", site.key)
      path = mount["path"].to_s
      error(site.key, "Path non normalizzato: #{path}") unless normalized_path?(path)

      resource = mount["resource"]
      unless resource.is_a?(Hash) && resource["type"] == "page" && resource["key"].present?
        error(site.key, "Mount #{mount['key']} deve puntare a una page")
        return
      end

      @repository.page(site, resource["key"])
    rescue SourceNotFoundError => exception
      error(site.key, exception.message)
    end

    def validate_page(site, page_key, mounted:)
      page_config = @repository.page(site, page_key)
      @counts[:pages] += 1
      schema_version(page_config, "pages/#{page_key}.yml", site.key)
      page = page_config["page"]
      unless page.is_a?(Hash)
        error(site.key, "#{page_key}.yml deve contenere page")
        return
      end

      required(page, %w[key owner_node_slug kind renderer title description status visibility], "page #{page_key}", site.key)
      error(site.key, "page.key non coincide con il file: #{page_key}") unless page["key"] == page_key
      error(site.key, "renderer non supportato: #{page['renderer']}") unless page["renderer"] == "builder"
      error(site.key, "status non valido: #{page['status']}") unless STATUSES.include?(page["status"])
      error(site.key, "visibility non valida: #{page['visibility']}") unless VISIBILITIES.include?(page["visibility"])
      warning(site.key, "Pagina montata ma non pubblicata: #{page_key}") if mounted && page["status"] != "published"
      warning(site.key, "Pagina valida ma non montata: #{page_key}") unless mounted

      components = page_config["components"]
      unless components.is_a?(Array)
        error(site.key, "components deve essere un elenco in #{page_key}")
        return
      end

      duplicates(components.filter_map { |component| component["id"] }).each do |id|
        error(site.key, "ID componente duplicato in #{page_key}: #{id}")
      end
      components.each { |component| validate_component(site.key, page_key, component) }
    end

    def validate_component(site_key, page_key, component)
      required(component, %w[id type], "component in #{page_key}", site_key)
      return unless component["type"].present?

      definition = ComponentRegistry.fetch(component["type"])
      variant = component.fetch("variant", "default")
      error(site_key, "Variante #{variant} non valida per #{component['type']}") unless definition.variants.include?(variant)

      data = component["data"] || {}
      error(site_key, "data deve essere una mappa per #{component['id']}") unless data.is_a?(Hash)
      return unless data.is_a?(Hash)

      required(data, definition.required_data, "data di #{component['id']}", site_key)
      if definition.items && !component["items"].is_a?(Array)
        error(site_key, "items deve essere un elenco per #{component['id']}")
      end

      validate_source(site_key, component)
    rescue UnknownComponentError => exception
      error(site_key, exception.message)
    end

    def required(hash, keys, context, site_key)
      keys.each { |key| error(site_key, "Campo obbligatorio mancante: #{context}.#{key}") if hash[key].blank? }
    end

    def normalized_path?(path)
      return true if path == "/"

      path.match?(PATH_PATTERN) && !path.end_with?("/")
    end

    def validate_source(site_key, component)
      source = component["source"]
      return if source.blank?

      unless source.is_a?(Hash) && source["type"].present?
        error(site_key, "source non valida per #{component['id']}")
        return
      end

      error(site_key, "Sorgente non registrata: #{source['type']}") unless SourceRegistry.registered?(source["type"])
      key = source["key"]
      return if source["type"] == "inline"

      error(site_key, "Chiave sorgente non valida per #{component['id']}") unless key.to_s.match?(SiteRepository::KEY_PATTERN)
    end

    def validate_redirects(site)
      canonical_paths = site.mounts.filter_map { |mount| mount["path"] }
      from_paths = site.redirects.filter_map { |redirect| redirect["from"] }
      duplicates(from_paths).each { |path| error(site.key, "Redirect duplicato: #{path}") }

      site.redirects.each do |redirect|
        from = redirect["from"].to_s
        destination = redirect["to"].to_s
        error(site.key, "Redirect non normalizzato: #{from}") unless normalized_path?(from)
        error(site.key, "Destinazione redirect inesistente: #{destination}") unless canonical_paths.include?(destination)
        error(site.key, "Redirect circolare: #{from}") if from == destination
      end
    end

    def schema_version(config, context, site_key)
      return if config["schema_version"] == SCHEMA_VERSION

      error(site_key, "schema_version non supportata in #{context}: #{config['schema_version'].inspect}")
    end

    def duplicates(values)
      values.tally.select { |_value, count| count > 1 }.keys
    end

    def error(site, message)
      @errors << "#{site}: #{message}"
    end

    def warning(site, message)
      @warnings << "#{site}: #{message}"
    end
  end
end
