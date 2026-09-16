module Editorial
  class PageResolver
    Context = Data.define(:site, :mount, :page_configuration, :page, :theme)

    def initialize(repository: SiteRepository.new)
      @repository = repository
    end

    def resolve(site_key, path: "/", preview: false)
      site = @repository.load(site_key)
      mount = path == "/" ? site.mount(site.site.dig("entrypoint", "mount")) : site.mount_for_path(path)
      raise SourceNotFoundError, "Mount non trovato: #{path}" unless mount

      resource = mount.fetch("resource")
      raise InvalidSourceError, "Tipo di risorsa non supportato: #{resource['type']}" unless resource["type"] == "page"

      page_configuration = @repository.page(site, resource.fetch("key"))
      page = page_configuration.fetch("page")
      authorize!(page) unless preview

      Context.new(
        site: site,
        mount: mount,
        page_configuration: page_configuration,
        page: page,
        theme: ThemeRegistry.fetch(site.site.fetch("theme"))
      )
    end

    private

    def authorize!(page)
      return if page["status"] == "published" && page["visibility"] == "public"

      raise SourceNotFoundError, "Pagina non disponibile"
    end
  end
end
