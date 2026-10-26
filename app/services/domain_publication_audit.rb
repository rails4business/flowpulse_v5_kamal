class DomainPublicationAudit
  Check = Data.define(:key, :label, :status, :detail, :path) do
    def ready? = status == :ready
    def warning? = status == :warning
    def blocked? = status == :blocked
  end

  Result = Data.define(:domain, :checks) do
    def status
      return :blocked if checks.any?(&:blocked?)
      return :attention if checks.any?(&:warning?)

      :ready
    end

    def count(status)
      checks.count { |check| check.status == status.to_sym }
    end

    def ready? = status == :ready
    def attention? = status == :attention
    def blocked? = status == :blocked
  end

  def initialize(domain, domains: Domain.all, performance_document: nil)
    @domain = domain
    @domains = domains.to_a
    @performance_document = performance_document || Performance::DomainBudgetCatalog.new.validate.document
    @policy = PublicDiscovery::AccessPolicy.new
  end

  def call
    return alias_result if domain.canonical_host.present?

    @checks = []
    inspect_activation
    inspect_entrypoint
    inspect_node
    inspect_identity
    inspect_assets
    inspect_security
    inspect_public_projection
    inspect_performance
    Result.new(domain, @checks.freeze)
  end

  private
    attr_reader :domain, :domains, :performance_document, :policy

    def alias_result
      canonical = domains.find { |candidate| candidate.hostname == domain.canonical_host }
      checks = [
        check(:active, "Host attivo", domain.active? ? :ready : :warning,
          domain.active? ? "L'alias può ricevere richieste." : "L'alias è disattivato."),
        check(:canonical, "Redirect canonico", canonical&.active? ? :ready : :blocked,
          canonical&.active? ? "Reindirizza a #{canonical.hostname}." : "Il dominio canonico non esiste o non è attivo.")
      ]
      Result.new(domain, checks.freeze)
    end

    def inspect_activation
      add(:active, "Dominio attivo", domain.active? ? :ready : :warning,
        domain.active? ? "Il dominio può essere servito dall'applicazione." : "Il dominio è intenzionalmente fuori pubblicazione.")
    end

    def inspect_entrypoint
      configured = domain.site_key.present? || (domain.target_controller.present? && domain.target_action.present?)
      detail = if domain.site_key.present?
        "Site editoriale: #{domain.site_key}."
      elsif configured
        "Destinazione: #{domain.target_controller}##{domain.target_action}."
      else
        "Manca un Site editoriale oppure una coppia controller/action."
      end
      add(:entrypoint, "Ingresso della landing", configured ? :ready : :blocked, detail, "/")
    end

    def inspect_node
      if domain.node.blank?
        add(:node, "Node radice", :blocked, "Il dominio canonico non è collegato a un Node.")
        return
      end

      add(:node, "Node radice", :ready, "#{domain.node.title} · #{domain.node.slug}.")
      public_node = policy.public_node?(domain.node)
      add(:node_visibility, "Pubblicazione del Node", public_node ? :ready : :blocked,
        public_node ? "Il Node è published/public." : "Impostare stato published e visibilità public per pubblicare il dominio.")
    end

    def inspect_identity
      missing = []
      missing << "titolo" if domain.site_title.blank?
      missing << "descrizione" if domain.site_description.blank?
      add(:identity, "Identità SEO", missing.empty? ? :ready : :warning,
        missing.empty? ? "Titolo e descrizione sono configurati." : "Da completare: #{missing.join(', ')}.")
    end

    def inspect_assets
      missing = []
      missing << "logo" if domain.logo_full_url.blank? && domain.logo_square_url.blank?
      missing << "favicon" if domain.favicon_url.blank?
      missing << "immagine social" if domain.social_image_url.blank?
      add(:assets, "Asset del dominio", missing.empty? ? :ready : :warning,
        missing.empty? ? "Logo, favicon e immagine social sono configurati." : "Da completare: #{missing.join(', ')}.")
    end

    def inspect_security
      explicit_profile = domain.security_profile.to_s.presence_in(PublicSubmissionSecurity::PROFILES.keys)
      if explicit_profile
        limits = PublicSubmissionSecurity::PROFILES.fetch(explicit_profile)
        add(:security, "Protezione form pubblici", :ready,
          "Profilo #{explicit_profile}: #{limits.fetch(:per_ip)} invii per IP ogni #{limits.fetch(:within).inspect}.")
      else
        add(:security, "Protezione form pubblici", :warning,
          "Si applica automaticamente il profilo standard, ma il dominio deve confermare un profilo esplicito.")
      end
    end

    def inspect_public_projection
      projection = PublicDiscovery::Projection.new(domain).call
      unless projection
        %i[html sitemap robots llms api].each do |key|
          add(key, public_label(key), :blocked, "Non disponibile finché il dominio e il Node radice non sono pubblici.", public_path(key))
        end
        return
      end

      add(:html, public_label(:html), :ready, "La landing può essere esposta anonimamente.", "/")
      inspect_sitemap(projection)
      add(:robots, public_label(:robots), :ready, "Le regole sono generate per questo host.", "/robots.txt")
      inspect_llms(projection)
      inspect_api(projection)
    end

    def inspect_sitemap(projection)
      urls = PublicDiscovery::DomainUrls.new(domain, projection:).call
      ready = urls.any? { |entry| entry[:loc] == "https://#{domain.hostname}/" }
      add(:sitemap, public_label(:sitemap), ready ? :ready : :blocked,
        ready ? "#{urls.size} URL pubblici, compresa la landing." : "La sitemap non contiene la landing canonica.", "/sitemap.xml")
    rescue StandardError => error
      add(:sitemap, public_label(:sitemap), :blocked, "Errore nella generazione: #{error.message}", "/sitemap.xml")
    end

    def inspect_llms(projection)
      unless domain.llms_discovery_enabled?
        add(:llms, public_label(:llms), :warning, "La discovery testuale per le AI è disattivata.", "/llms.txt")
        return
      end

      document = PublicDiscovery::LlmsDocument.new(domain, projection:).call
      add(:llms, public_label(:llms), document.present? ? :ready : :blocked,
        document.present? ? "Documento generato dalla proiezione pubblica." : "Il documento non può essere generato.", "/llms.txt")
    rescue StandardError => error
      add(:llms, public_label(:llms), :blocked, "Errore nella generazione: #{error.message}", "/llms.txt")
    end

    def inspect_api(projection)
      valid = projection["domain"].present? && projection["root_node"].present? &&
        projection["nodes"].is_a?(Array) && projection["resources"].is_a?(Array)
      detail = if valid
        "Schema v#{projection['schema_version']} · #{projection['nodes'].size + 1} Node · #{projection['resources'].size} risorse."
      else
        "La proiezione pubblica non rispetta il contratto previsto."
      end
      add(:api, public_label(:api), valid ? :ready : :blocked, detail, "/api/v1/domain")
    end

    def inspect_performance
      configuration = performance_document.fetch("domains", {}).fetch(domain.hostname, nil)
      unless configuration
        add(:performance, "PageSpeed mobile", :warning, "Manca il budget per questo dominio nel catalogo performance.")
        return
      end

      baseline = configuration.fetch("baseline", {})
      case baseline["status"]
      when "measured"
        add(:performance, "PageSpeed mobile", :ready, "Baseline misurata; confrontare i valori con i budget condivisi.")
      when "skipped"
        add(:performance, "PageSpeed mobile", :warning, "Misurazione rinviata: #{baseline['reason']}".strip)
      else
        pages = Array(configuration["pages"]).map { |page| page["path"] }.compact
        add(:performance, "PageSpeed mobile", :warning, "Baseline da misurare esternamente su: #{pages.join(', ')}.")
      end
    end

    def public_label(key)
      {
        html: "Landing pubblica",
        sitemap: "Sitemap",
        robots: "Robots",
        llms: "llms.txt",
        api: "API pubblica"
      }.fetch(key)
    end

    def public_path(key)
      {
        html: "/",
        sitemap: "/sitemap.xml",
        robots: "/robots.txt",
        llms: "/llms.txt",
        api: "/api/v1/domain"
      }.fetch(key)
    end

    def add(key, label, status, detail, path = nil)
      @checks << check(key, label, status, detail, path)
    end

    def check(key, label, status, detail, path = nil)
      Check.new(key.to_sym, label, status.to_sym, detail, path)
    end
end
