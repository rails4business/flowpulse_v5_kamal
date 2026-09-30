class BrandNodeSnapshot
  VERSION = 1
  KEY_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  ATTRIBUTES = %w[title description node_type view_type status visibility operator_roles].freeze

  def self.for_slug(slug, path: nil)
    normalized_slug = slug.to_s
    raise ArgumentError, "Slug Brand non valido" unless normalized_slug.match?(KEY_PATTERN)

    brand = Node.includes(role_assignment: :profile).find_by!(slug: normalized_slug)
    raise ArgumentError, "#{normalized_slug} non è un Brand" unless brand.brand?

    new(brand:, path:)
  end

  def initialize(brand:, path: nil)
    @brand = brand
    @path = Pathname(path || Rails.root.join("config/data/brands", brand.slug, "nodes.yml"))
  end

  attr_reader :brand, :path

  def export!
    path.dirname.mkpath
    path.write(YAML.dump(document))
    path
  end

  def import!(dry_run: false)
    payload = load_payload
    definitions = payload.fetch("nodes").to_h.deep_stringify_keys
    validate_definitions!(definitions)
    imported = {}

    ActiveRecord::Base.transaction do
      definitions.each_key { |slug| import_node!(slug, definitions, imported, []) }

      definitions.each do |slug, attributes|
        target_slug = attributes["link_node_slug"].presence
        imported.fetch(slug).update!(link_node: target_slug ? Node.find_by!(slug: target_slug) : nil)
      end

      raise ActiveRecord::Rollback if dry_run
    end

    imported.size
  end

  def document
    nodes = brand.self_and_descendants.includes(:link_node, role_assignment: :profile).order(:position, :id)

    {
      "version" => VERSION,
      "brand" => brand.slug,
      "nodes" => nodes.index_with { |node| serialized_node(node) }.transform_keys(&:slug)
    }
  end

  private

    def load_payload
      raise ArgumentError, "Snapshot Node mancante: #{path.relative_path_from(Rails.root)}" unless path.file?

      payload = YAML.safe_load_file(path, permitted_classes: [], aliases: false).to_h.deep_stringify_keys
      raise ArgumentError, "Versione snapshot non supportata" unless payload.fetch("version") == VERSION
      raise ArgumentError, "Snapshot destinato a un altro Brand" unless payload.fetch("brand") == brand.slug

      payload
    end

    def validate_definitions!(definitions)
      raise ArgumentError, "Lo snapshot non contiene nodi" if definitions.empty?
      raise ArgumentError, "Manca il nodo radice #{brand.slug}" unless definitions.key?(brand.slug)

      definitions.each do |slug, attributes|
        raise ArgumentError, "Slug Node non valido: #{slug}" unless slug.match?(KEY_PATTERN)
        raise ArgumentError, "Node #{slug}: title mancante" if attributes["title"].blank?

        parent_slug = attributes["parent_slug"].presence
        if parent_slug.present? && !definitions.key?(parent_slug) && !Node.exists?(slug: parent_slug)
          raise ArgumentError, "Node #{slug}: parent_slug sconosciuto #{parent_slug}"
        end

        link_slug = attributes["link_node_slug"].presence
        if link_slug.present? && !definitions.key?(link_slug) && !Node.exists?(slug: link_slug)
          raise ArgumentError, "Node #{slug}: link_node_slug sconosciuto #{link_slug}"
        end
      end
    end

    def import_node!(slug, definitions, imported, stack)
      return imported.fetch(slug) if imported.key?(slug)
      raise ArgumentError, "Ciclo parent rilevato: #{(stack + [slug]).join(' → ')}" if stack.include?(slug)

      attributes = definitions.fetch(slug)
      parent_slug = attributes["parent_slug"].presence
      parent = if parent_slug && definitions.key?(parent_slug)
        import_node!(parent_slug, definitions, imported, stack + [slug])
      elsif parent_slug
        Node.find_by!(slug: parent_slug)
      end

      node = Node.find_by(slug:)
      if node && node != brand && !brand.self_and_descendants.exists?(id: node.id)
        raise ArgumentError, "Node #{slug}: lo slug appartiene a un altro albero"
      end
      node ||= Node.new(slug:)
      node.assign_attributes(attributes.slice(*ATTRIBUTES))
      node.parent = parent
      node.role_assignment = parent&.role_assignment || brand.role_assignment
      node.position = attributes["position"] if attributes["position"].present?
      node.save!
      imported[slug] = node
    end

    def serialized_node(node)
      {
        "title" => node.title,
        "description" => node.description.presence,
        "parent_slug" => node.parent&.slug,
        "position" => node.position,
        "node_type" => node.node_type,
        "view_type" => node.view_type,
        "status" => node.status,
        "visibility" => node.visibility,
        "operator_roles" => node.operator_roles.presence,
        "link_node_slug" => node.link_node&.slug
      }.compact
    end
end
