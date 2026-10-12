class DomainArchitectureAudit
  Issue = Data.define(:severity, :code, :message)

  Result = Data.define(:issues_by_domain_id) do
    def issues_for(domain)
      issues_by_domain_id.fetch(domain.id, [])
    end

    def count(severity)
      issues_by_domain_id.values.flatten.count { |issue| issue.severity == severity.to_sym }
    end

    def domains_with_issues
      issues_by_domain_id.count { |_id, issues| issues.any? }
    end
  end

  def initialize(domains, site_configs: nil, site_keys: nil)
    @domains = domains.to_a
    @site_configs = site_configs || legacy_site_configs(site_keys) || available_site_configs
  end

  def call
    @issues = @domains.index_with { [] }
    @domains.each { |domain| inspect_domain(domain) }
    inspect_primary_domains

    Result.new(@issues.transform_keys(&:id))
  end

  private
    def inspect_domain(domain)
      if domain.canonical_host.present?
        inspect_alias(domain)
        return
      end

      add(domain, :error, :missing_node, "Il dominio canonico deve avere un Node radice") if domain.node.blank?
      add(domain, :error, :missing_entrypoint, "Manca Site o destinazione controller/action") unless entrypoint?(domain)
      if domain.active? && domain.node.present? && !PublicDiscovery::AccessPolicy.new.public_domain?(domain)
        add(domain, :warning, :excluded_from_public_discovery, "Escluso da motori di ricerca, API e AI: il Node radice non è published/public")
      end

      inspect_site(domain) if domain.site_key.present?

      missing_metadata = {
        site_title: "titolo",
        site_description: "descrizione",
        favicon_url: "favicon",
        social_image_url: "immagine social"
      }.filter_map { |attribute, label| label if domain.public_send(attribute).blank? }

      if missing_metadata.any?
        add(domain, :warning, :missing_metadata, "Metadata incompleti: #{missing_metadata.join(', ')}")
      end
    end

    def inspect_alias(domain)
      canonical = @domains.find { |candidate| candidate.hostname == domain.canonical_host }
      add(domain, :error, :missing_canonical, "Host canonico #{domain.canonical_host.inspect} non configurato") if canonical.blank?
      add(domain, :warning, :inactive_canonical, "Host canonico non attivo") if canonical.present? && !canonical.active?
      add(domain, :error, :primary_alias, "Un alias non può essere dominio primario") if domain.primary?
      add(domain, :warning, :alias_with_node, "L'alias eredita il Node dal dominio canonico") if domain.node.present?
      add(domain, :warning, :alias_with_site, "L'alias eredita il Site dal dominio canonico") if domain.site_key.present?
    end

    def inspect_site(domain)
      site = @site_configs[domain.site_key]
      unless site
        add(domain, :error, :unknown_site, "Site #{domain.site_key.inspect} non trovato")
        return
      end

      site_node_slug = site["node_slug"].to_s.presence
      if site_node_slug.blank?
        add(domain, :error, :site_without_node, "Il Site non dichiara node_slug")
      elsif domain.node.present? && site_node_slug != domain.node.slug
        add(domain, :error, :site_node_mismatch, "Il Site appartiene al Node #{site_node_slug.inspect}, il Domain a #{domain.node.slug.inspect}")
      end

      site_locale = site["locale"].to_s.presence
      if site_locale.present? && site_locale != domain.locale
        add(domain, :error, :site_locale_mismatch, "Lingua Site #{site_locale.inspect} diversa dal Domain #{domain.locale.inspect}")
      end
    end

    def inspect_primary_domains
      @domains.reject { |domain| domain.canonical_host.present? || domain.node.blank? }
        .group_by { |domain| [domain.node_id, domain.locale] }
        .each_value do |domains|
          primary_domains = domains.select(&:primary?)

          if primary_domains.size > 1
            primary_domains.each { |domain| add(domain, :error, :multiple_primary, "Più domini primari per lo stesso Node e lingua") }
          elsif domains.size > 1 && primary_domains.empty?
            domains.each { |domain| add(domain, :warning, :missing_primary, "Nessun dominio primario per questo Node e lingua") }
          end
        end
    end

    def entrypoint?(domain)
      domain.site_key.present? || (domain.target_controller.present? && domain.target_action.present?)
    end

    def available_site_configs
      Rails.root.glob("config/data/sites/*/site.yml").to_h do |path|
        data = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
        [path.dirname.basename.to_s, data.fetch("site", {}).to_h]
      end
    end

    def legacy_site_configs(site_keys)
      return if site_keys.nil?

      site_keys.index_with { {} }
    end

    def add(domain, severity, code, message)
      @issues.fetch(domain) << Issue.new(severity.to_sym, code.to_sym, message)
    end
end
