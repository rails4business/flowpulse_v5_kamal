class NodeCatalogEntryWriter
  PATH = Rails.root.join("config/nodes.yml")

  def initialize(node, path: PATH)
    @node = node
    @path = Pathname(path)
  end

  def write!
    raise "Editor catalogo Node non abilitato" unless NodeCatalogEditor.enabled?

    source = path.read
    replacement = serialized_entry
    pattern = /^    #{Regexp.escape(node.slug)}:\n.*?(?=^    [a-z0-9][a-z0-9-]*:\n|^development:|\z)/m
    updated = if source.match?(pattern)
      source.sub(pattern, replacement)
    else
      source.sub(/^development:/, "#{replacement}\ndevelopment:")
    end
    raise "Impossibile aggiornare config/nodes.yml" if updated == source

    path.write(updated)
    path
  end

  private

  attr_reader :node, :path

  def serialized_entry
    yaml = YAML.dump({ node.slug => attributes }).delete_prefix("---\n")
    yaml.lines.map { |line| "    #{line}" }.join.rstrip + "\n\n"
  end

  def attributes
    existing = Rails.application.config_for(:nodes, env: Rails.env).to_h.deep_stringify_keys.fetch("nodes", {}).to_h
      .fetch(node.slug, {}).to_h.deep_stringify_keys
    values = {
      "title" => node.title,
      "description" => node.description.presence,
      "node_type" => node.node_type,
      "view_type" => node.view_type == "default" ? nil : node.view_type,
      "parent_slug" => node.parent&.slug,
      "position" => node.position,
      "map_color" => node.map_color.presence,
      "professional_owner_slug" => node.professional_owner_node&.slug,
      "status" => node.status,
      "visibility" => node.visibility,
      "operator_roles" => node.operator_roles.presence,
      "link_node_slug" => node.link_node&.slug,
      "navigation" => node.navigation
    }
    values["owner_username"] = node.role_assignment.profile.username if node.parent.blank?
    existing.merge(values).compact
  end
end
