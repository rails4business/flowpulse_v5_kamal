class NodeCatalog
  Result = Data.define(:nodes, :profiles)

  ALLOWED_ATTRIBUTES = %w[
    title description node_type view_type status visibility
    operator_roles
  ].freeze

  def self.from_config(environment = Rails.env)
    new(Rails.application.config_for(:nodes, env: environment))
  end

  def initialize(config)
    @config = config.to_h.deep_stringify_keys
    @definitions = @config.fetch("nodes", {}).to_h.deep_stringify_keys
  end

  def validate!
    raise ArgumentError, "config/nodes.yml non contiene nodes" if definitions.empty?

    definitions.each do |slug, attributes|
      raise ArgumentError, "Node #{slug}: title mancante" if attributes["title"].blank?

      %w[parent_slug professional_owner_slug].each do |reference|
        next if attributes[reference].blank? || definitions.key?(attributes[reference])

        raise ArgumentError, "Node #{slug}: #{reference} sconosciuto #{attributes[reference]}"
      end
    end

    detect_parent_cycles!
    true
  end

  def import!(dry_run: false)
    validate!
    imported = {}
    associated_profiles = 0

    ActiveRecord::Base.transaction do
      definitions.each_key { |slug| import_node!(slug, imported, []) }

      definitions.each do |slug, attributes|
        node = imported.fetch(slug)
        owner_slug = attributes["professional_owner_slug"].presence
        node.update!(professional_owner_node: owner_slug ? imported.fetch(owner_slug) : nil)

        username = attributes["primary_profile_username"].presence
        next if username.blank?

        profile = Profile.find_by!(username: username)
        profile.update!(primary_node: node)
        associated_profiles += 1
      end

      raise ActiveRecord::Rollback if dry_run
    end

    Result.new(nodes: imported.size, profiles: associated_profiles)
  end

  private

    attr_reader :definitions

    def import_node!(slug, imported, stack)
      return imported.fetch(slug) if imported.key?(slug)
      raise ArgumentError, "Ciclo parent rilevato: #{(stack + [slug]).join(' → ')}" if stack.include?(slug)

      attributes = definitions.fetch(slug)
      parent_slug = attributes["parent_slug"].presence
      parent = import_node!(parent_slug, imported, stack + [slug]) if parent_slug
      role_assignment = parent&.role_assignment || find_root_role_assignment!(slug, attributes)

      matches = Node.where(slug: slug).limit(2).to_a
      raise ArgumentError, "Slug Node non univoco nel database: #{slug}" if matches.many?

      node = matches.first || Node.new(slug: slug)
      node.assign_attributes(attributes.slice(*ALLOWED_ATTRIBUTES))
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
