module DashboardNavigation
  class Registry
    Section = Data.define(:key, :title, :description, :code, :path)
    BRAND_SECTIONS = [
      [:nodes, "Nodi", "Struttura, progetti e risorse del Brand.", "NOD", "nodes"],
      [:schema, "Schema", "Vista strutturale dei Node e dei collegamenti.", "SCH", "nodes?view=schema"],
      [:development, "Sviluppo", "Decisioni, interventi e stato dello sviluppo.", "DEV", "development"],
      [:requests, "Richieste", "Richieste e accessi del perimetro consentito.", "REQ", "requests"],
      [:contents, "Contenuti", "Contenuti editoriali pubblicati dal Brand.", "CON", "contents"],
      [:data_commitments, "Impegni", "Attività e impegni collegati al Brand.", "IMP", "data-commitments"],
      [:privacy, "Privacy", "Configurazione privacy e protezione dei dati.", "PRI", "privacy"],
      [:brand_people, "Persone", "Profile e accessi dell’intero Brand.", "PER", "people"],
      [:projects, "Progetti", "Progetti consentiti e persone dei singoli progetti.", "PRJ", "projects"]
    ].freeze

    def initialize(context:, paths: Paths.new(context: context))
      @context = context
      @paths = paths
      @policy = Policy.new(context: context)
    end

    def sections
      return platform_sections if policy.platform?

      BRAND_SECTIONS.filter_map do |key, title, description, code, suffix|
        Section.new(key: key, title: title, description: description, code: code, path: paths.brand(suffix)) if policy.allowed?(key)
      end
    end

    def sidebar
      home_title = context.brand&.title.presence || "FlowPulse"
      items = [Section.new(key: :brand_home, title: home_title, description: "Home del sito", code: "HOME", path: paths.home)]
      if policy.allowed?(:dashboard)
        items << Section.new(key: :brand_dashboard, title: policy.platform? ? "Amministrazione" : "Dashboard",
          description: "Le funzioni disponibili nel tuo perimetro", code: "ADM", path: paths.dashboard)
      end
      if context.superadmin? && !policy.platform?
        items << Section.new(key: :flowpulse_admin, title: "Amministrazione FlowPulse",
          description: "Profile e controllo globale", code: "SYS", path: paths.platform)
      elsif context.user && !policy.allowed?(:dashboard)
        items << Section.new(key: :profile, title: "Profilo", description: "Dati personali e accessi", code: "USR", path: paths.route(:profile_path))
      end
      items
    end

    private

      attr_reader :context, :paths, :policy

      def platform_sections
        return [] unless policy.allowed?(:platform)

        entries = [
          Section.new(key: :profiles, title: "Persone e Profile", description: "Identità, BrandAccess e incarichi.",
            code: "PER", path: paths.platform(paths.route(:admin_profiles_path))),
          Section.new(key: :brands, title: "Brand e domini", description: "Brand, progetti e configurazione dei domini.",
            code: "BRD", path: paths.platform(paths.route(:admin_brands_path))),
          Section.new(key: :prototype, title: "Prototipo dashboard", description: "Riferimento storico per le viste amministrative.",
            code: "HTML", path: paths.platform(paths.route(:admin_prototype_path,
              path: "viste_html/Dashboard · generaimpresa · originale 2026-10-19.html")))
        ]
        FlowRoles::MenuRegistry.items.each do |item|
          next if item.key == :dashboard

          path = item.path.is_a?(Symbol) ? paths.route(item.path) : item.path
          entries << Section.new(key: item.key, title: item.title, description: item.subtitle, code: item.badge, path: paths.platform(path))
        end
        entries.uniq(&:path)
      end
  end
end
