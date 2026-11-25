module RoleDefinitions
  module Registry
    Definition = Data.define(
      :code,
      :label,
      :brand_slugs,
      :capabilities,
      :delegatable,
      :inheritable,
      :delegatable_role_codes,
      :limits
    )

    DEFINITIONS = {
      "imprenditore_generaimpresa" => Definition.new(
        code: "imprenditore_generaimpresa",
        label: "Imprenditore GeneraImpresa",
        brand_slugs: %w[generaimpresa],
        capabilities: %i[read manage create_children manage_access],
        delegatable: false,
        inheritable: true,
        delegatable_role_codes: [],
        limits: { managed_nodes_per_brand: 7 }
      ),
      "insegnante_posturacorretta" => Definition.new(
        code: "insegnante_posturacorretta",
        label: "Insegnante PosturaCorretta",
        brand_slugs: %w[posturacorretta],
        capabilities: %i[read teach manage_lessons],
        delegatable: false,
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "professionista_percorso_integrato" => Definition.new(
        code: "professionista_percorso_integrato",
        label: "Professionista Percorso Integrato",
        brand_slugs: %w[percorso-integrato],
        capabilities: %i[read manage_clients],
        delegatable: false,
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "professionista_rails4business" => Definition.new(
        code: "professionista_rails4business",
        label: "Professionista Rails4Business",
        brand_slugs: %w[rails4business rails4b],
        capabilities: %i[read manage_projects],
        delegatable: false,
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "organizzatore_eventi_ilgiardinodelcorpo" => Definition.new(
        code: "organizzatore_eventi_ilgiardinodelcorpo",
        label: "Organizzatore eventi Il Giardino del Corpo",
        brand_slugs: %w[ilgiardinodelcorpo il-giardino-del-corpo],
        capabilities: %i[read manage_events],
        delegatable: false,
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "segreteria" => Definition.new(
        code: "segreteria",
        label: "Segreteria",
        brand_slugs: [],
        capabilities: %i[read manage_office],
        delegatable: false,
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      )
    }.freeze

    ALIASES = {
      "creator_generaimpresa" => "imprenditore_generaimpresa"
    }.freeze

    module_function

    def canonical_code(code)
      normalized = code.to_s.strip.downcase.presence
      ALIASES.fetch(normalized, normalized)
    end

    def fetch(code)
      DEFINITIONS.fetch(canonical_code(code))
    end

    def find(code)
      DEFINITIONS[canonical_code(code)]
    end

    def registered?(code)
      find(code).present?
    end

    def all
      DEFINITIONS.values
    end

    def compatible_with_brand?(code, brand_node)
      definition = find(code)
      return false unless definition && brand_node
      return true if definition.brand_slugs.empty?

      definition.brand_slugs.include?(brand_node.slug)
    end
  end
end
