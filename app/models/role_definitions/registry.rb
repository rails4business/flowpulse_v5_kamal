module RoleDefinitions
  module Registry
    Definition = Data.define(
      :code,
      :label,
      :scope,
      :enabled,
      :brand_slugs,
      :node_types,
      :capabilities,
      :inheritable,
      :delegatable_role_codes,
      :limits
    ) do
      def initialize(scope: :brand, enabled: true, node_types: %w[professional project], **attributes)
        if scope == :brand && attributes.fetch(:brand_slugs).empty?
          raise ArgumentError, "Un ruolo di Brand deve dichiarare i Brand compatibili"
        end
        unless scope.in?(%i[brand shared])
          raise ArgumentError, "Tipo di ruolo contestuale non valido"
        end

        values = attributes.merge(scope: scope, enabled: enabled, node_types: node_types)
        super(**values.transform_values do |value|
          case value
          when Array then value.map(&:freeze).freeze
          when Hash then value.dup.freeze
          else value.freeze
          end
        end)
      end

      def compatible_with_brand?(brand_node)
        enabled && brand_node.present? && (scope == :shared || brand_slugs.include?(brand_node.slug))
      end

      def delegates_to?(definition, brand_node:)
        compatible_with_brand?(brand_node) && definition&.compatible_with_brand?(brand_node) &&
          delegatable_role_codes.include?(definition.code)
      end
    end

    DEFINITIONS = {
      "gestore_generaimpresa" => Definition.new(
        code: "gestore_generaimpresa",
        label: "Gestore GeneraImpresa",
        brand_slugs: %w[generaimpresa],
        capabilities: %i[read manage manage_access manage_requests manage_projects],
        inheritable: true,
        delegatable_role_codes: [],
        limits: {}
      ),
      "imprenditore_generaimpresa" => Definition.new(
        code: "imprenditore_generaimpresa",
        label: "Imprenditore GeneraImpresa",
        brand_slugs: %w[generaimpresa],
        capabilities: %i[read manage create_children manage_access],
        inheritable: true,
        delegatable_role_codes: [],
        limits: { managed_nodes_per_brand: 7 }
      ),
      "insegnante_posturacorretta" => Definition.new(
        code: "insegnante_posturacorretta",
        label: "Insegnante PosturaCorretta",
        brand_slugs: %w[posturacorretta],
        capabilities: %i[read teach manage_lessons],
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "professionista_percorso_integrato" => Definition.new(
        code: "professionista_percorso_integrato",
        label: "Professionista Percorso Integrato",
        brand_slugs: %w[percorso-integrato],
        capabilities: %i[read manage_clients],
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "professionista_rails4business" => Definition.new(
        code: "professionista_rails4business",
        label: "Professionista Rails4Business",
        brand_slugs: %w[rails4business rails4b],
        capabilities: %i[read manage_projects],
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "organizzatore_eventi_ilgiardinodelcorpo" => Definition.new(
        code: "organizzatore_eventi_ilgiardinodelcorpo",
        label: "Organizzatore eventi Il Giardino del Corpo",
        brand_slugs: %w[ilgiardinodelcorpo il-giardino-del-corpo],
        capabilities: %i[read manage_events],
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      ),
      "segreteria" => Definition.new(
        code: "segreteria",
        label: "Segreteria",
        scope: :shared,
        enabled: false,
        brand_slugs: [],
        capabilities: %i[read manage_office],
        inheritable: false,
        delegatable_role_codes: [],
        limits: {}
      )
    }.freeze

    ALIASES = {
      "creator_generaimpresa" => "imprenditore_generaimpresa"
    }.transform_values(&:freeze).freeze

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
      find(code)&.compatible_with_brand?(brand_node) || false
    end

    def assignable_to?(code, brand_node:, node:)
      definition = find(code)
      compatible_with_brand?(code, brand_node) && node.is_a?(Node) && definition.node_types.include?(node.node_type)
    end

    def for_brand(brand_node)
      all.select { |definition| definition.compatible_with_brand?(brand_node) }
    end

    def delegation_allowed?(from:, to:, brand_node:)
      find(from)&.delegates_to?(find(to), brand_node: brand_node) || false
    end
  end
end
