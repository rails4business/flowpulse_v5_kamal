class NodeCatalog
  Result = Data.define(:nodes, :profiles, :pruned)

  ALLOWED_ATTRIBUTES = %w[
    title description node_type view_type status visibility
    operator_roles map_color position lane_container line_slugs offer_slugs
  ].freeze

  def self.from_config(environment = Rails.env)
    new(Rails.application.config_for(:nodes, env: environment), validate_line_offers: true)
  end

  def initialize(config = nil, validate_line_offers: false, **config_keywords)
    config ||= config_keywords
    @config = config.to_h.deep_stringify_keys
    @definitions = @config.fetch("nodes", {}).to_h.deep_stringify_keys
    @removed_slugs = Array(@config["removed_slugs"]).filter_map(&:presence)
    @validate_line_offers = validate_line_offers
  end

  def validate!
    raise ArgumentError, "config/nodes.yml non contiene nodes" if definitions.empty?

    definitions.each do |slug, attributes|
      raise ArgumentError, "Node #{slug}: title mancante" if attributes["title"].blank?

      %w[parent_slug professional_owner_slug].each do |reference|
        next if attributes[reference].blank? || definitions.key?(attributes[reference])

        raise ArgumentError, "Node #{slug}: #{reference} sconosciuto #{attributes[reference]}"
      end

      link_slug = attributes["link_node_slug"].presence
      if link_slug.present? && !definitions.key?(link_slug)
        raise ArgumentError, "Node #{slug}: link_node_slug sconosciuto #{link_slug}"
      end

      attributes.fetch("map_placements", {}).to_h.each do |hostname, placement|
        Float(placement.to_h.fetch("x"))
        Float(placement.to_h.fetch("y"))
      rescue KeyError, ArgumentError, TypeError
        raise ArgumentError, "Node #{slug}: coordinate non valide per la mappa #{hostname}"
      end


      navigation_slugs(attributes["navigation"]).each do |navigation_slug|
        next if definitions.key?(navigation_slug)

        raise ArgumentError, "Node #{slug}: navigation riferisce lo slug sconosciuto #{navigation_slug}"
      end
    end

    detect_parent_cycles!
    duplicate_removed_slugs = removed_slugs & definitions.keys
    if duplicate_removed_slugs.any?
      raise ArgumentError, "Node presenti sia nel catalogo sia in removed_slugs: #{duplicate_removed_slugs.join(', ')}"
    end
    LineOfferCatalog.from_config.validate!(node_definitions: definitions) if validate_line_offers
    true
  end

  def import!(dry_run: false, prune: false, remove_configured: true)
    validate!
    if prune && Rails.env.production?
      raise ArgumentError, "Il pruning del catalogo Node non è consentito in produzione"
    end

    imported = {}
    associated_profiles = 0
    pruned = 0

    ActiveRecord::Base.transaction do
      definitions.each_key { |slug| import_node!(slug, imported, []) }

      definitions.each do |slug, attributes|
        node = imported.fetch(slug)
        owner_slug = attributes["professional_owner_slug"].presence
        link_slug = attributes["link_node_slug"].presence
        node.update!(
          professional_owner_node: owner_slug ? imported.fetch(owner_slug) : nil,
          link_node: link_slug ? imported.fetch(link_slug) : nil,
          navigation: attributes["navigation"]
        )

        username = attributes["primary_profile_username"].presence
        next if username.blank?

        profile = Profile.find_by!(username: username)
        profile.update!(primary_node: node)
        associated_profiles += 1
      end

      removed_slugs.each do |slug|
        node = Node.find_by(slug:)
        next unless node

        if remove_configured
          remove_node!(node)
          pruned += 1
        else
          node.update!(line_slugs: [], offer_slugs: [])
        end
      end

      if prune
        removable_nodes = Node.where.not(slug: definitions.keys).to_a
          .sort_by { |node| -node.self_and_ancestors.count }
        removable_nodes.each do |node|
          next unless Node.exists?(node.id)

          node.destroy!
          pruned += 1
        end
      end

      raise ActiveRecord::Rollback if dry_run
    end

    Result.new(nodes: imported.size, profiles: associated_profiles, pruned: pruned)
  end

  def remove_configured!
    removed = 0
    ActiveRecord::Base.transaction do
      removed_slugs.each do |slug|
        node = Node.find_by(slug:)
        next unless node

        remove_node!(node)
        removed += 1
      end
    end
    removed
  end

  private

    attr_reader :definitions, :removed_slugs, :validate_line_offers

    def remove_node!(node)
      if node.children.exists? || node.domains.exists?
        raise ArgumentError, "Impossibile rimuovere il Node #{node.slug}: possiede ancora figli o domini"
      end
      node.destroy!
    end

    def navigation_slugs(navigation)
      items = navigation.to_h["items"] || navigation.to_h[:items]
      Array(items).flat_map do |item|
        attributes = item.to_h.stringify_keys
        slug = attributes["slug"] unless attributes["group"] || attributes["home"] || attributes["path"].present?
        [slug, *navigation_slugs("items" => attributes["children"])]
      end.compact
    end

    def import_node!(slug, imported, stack)
      return imported.fetch(slug) if imported.key?(slug)
      raise ArgumentError, "Ciclo parent rilevato: #{(stack + [slug]).join(' → ')}" if stack.include?(slug)

      attributes = definitions.fetch(slug)
      parent_slug = attributes["parent_slug"].presence
      parent = import_node!(parent_slug, imported, stack + [slug]) if parent_slug
      role_assignment = parent&.role_assignment || find_root_role_assignment!(slug, attributes)

      legacy_slugs = Array(attributes["legacy_slugs"]).filter_map(&:presence)
      matches = Node.where(slug: [slug, *legacy_slugs]).limit(3).to_a
      raise ArgumentError, "Slug Node non univoco nel database: #{slug}" if matches.many?

      node = matches.first || Node.new
      node.slug = slug
      # Linee e offerte assenti nel catalogo vengono svuotate, così toglierle dallo YAML le toglie anche dal Node.
      node.assign_attributes({ "line_slugs" => [], "offer_slugs" => [] }.merge(attributes.slice(*ALLOWED_ATTRIBUTES)))
      node.parent = parent
      node.role_assignment = role_assignment
      node.save!
      imported[slug] = node
    end

    def find_root_role_assignment!(slug, attributes)
      username = attributes["owner_username"].presence
      raise ArgumentError, "Node radice #{slug}: owner_username mancante" if username.blank?

      RoleAssignment.joins(:profile).find_by!(
        role: RoleAssignment.roles.fetch("ideatore"),
        profiles: { username: username }
      )
    end

    def detect_parent_cycles!
      definitions.each_key do |slug|
        visited = []
        current = slug

        while current.present?
          raise ArgumentError, "Ciclo parent rilevato: #{(visited + [current]).join(' → ')}" if visited.include?(current)

          visited << current
          current = definitions.fetch(current)["parent_slug"].presence
        end
      end
    end
end
