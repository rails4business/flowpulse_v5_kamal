class MetroMapCatalog
  Result = Data.define(:maps, :placements)

  def self.from_config(environment = Rails.env)
    new(
      Rails.application.config_for(:metro_maps, env: environment),
      nodes_config: Rails.application.config_for(:nodes, env: environment)
    )
  end

  # Tabella sessioni × slot da disegnare sotto la mappa del dominio, se configurata.
  def self.grid_for(hostname, environment = Rails.env)
    Rails.application.config_for(:metro_maps, env: environment).to_h.deep_stringify_keys.dig("maps", hostname, "grid")
  end

  def initialize(config, nodes_config: {})
    @definitions = config.to_h.deep_stringify_keys.fetch("maps", {}).to_h
    @placements_by_hostname = collect_placements(nodes_config.to_h.deep_stringify_keys.fetch("nodes", {}).to_h)
  end

  def validate!
    definitions.each do |hostname, attributes|
      raise ArgumentError, "Mappa #{hostname}: title mancante" if attributes["title"].blank?
      raise ArgumentError, "Mappa #{hostname}: dominio sconosciuto" unless Domain.find_for_host(hostname)
      if attributes.key?("placements")
        raise ArgumentError, "Mappa #{hostname}: le posizioni vanno in config/nodes.yml (map_placements)"
      end
      validate_grid!(hostname, attributes["grid"]) if attributes.key?("grid")
    end
    placements_by_hostname.each do |hostname, placements|
      raise ArgumentError, "Mappa #{hostname}: dominio sconosciuto" unless Domain.find_for_host(hostname)
      placements.each do |slug, placement|
        raise ArgumentError, "Mappa #{hostname}: Node sconosciuto #{slug}" unless Node.exists?(slug:)
        Float(placement.fetch("x"))
        Float(placement.fetch("y"))
      rescue KeyError, ArgumentError, TypeError
        raise ArgumentError, "Mappa #{hostname}: coordinate non valide per #{slug}"
      end
    end
    true
  end

  def import!
    validate!
    placement_count = 0
    ActiveRecord::Base.transaction do
      (definitions.keys | placements_by_hostname.keys).each do |hostname|
        attributes = definitions.fetch(hostname, {})
        domain = Domain.find_for_host(hostname).canonical_domain_record
        map = MetroMap.find_or_initialize_by(domain:)
        map.update!(
          title: attributes["title"].presence || map.title.presence || "Metropolitana #{domain.display_hostname}",
          status: attributes["status"].presence || map.status
        )
        placements_by_hostname.fetch(hostname, {}).each do |slug, placement|
          map.placements.find_or_initialize_by(node: Node.find_by!(slug:)).update!(
            x: placement.fetch("x"), y: placement.fetch("y"), collapsed: placement.fetch("collapsed", false)
          )
          placement_count += 1
        end
      end
    end
    Result.new(maps: (definitions.keys | placements_by_hostname.keys).size, placements: placement_count)
  end

  private

    attr_reader :definitions, :placements_by_hostname

    def validate_grid!(hostname, grid)
      Float(grid.fetch("first_x"))
      raise ArgumentError unless Float(grid.fetch("column_step")).positive?
      rows = grid.fetch("rows")
      raise ArgumentError if rows.blank?
      rows.each do |row|
        Float(row.fetch("y"))
        raise ArgumentError if row.fetch("label").blank?
      end
    rescue KeyError, ArgumentError, TypeError, NoMethodError
      raise ArgumentError, "Mappa #{hostname}: griglia non valida (servono first_x, column_step e rows con y e label)"
    end

    def collect_placements(node_definitions)
      node_definitions.each_with_object({}) do |(slug, attributes), placements|
        attributes.to_h.fetch("map_placements", {}).to_h.each do |hostname, placement|
          (placements[hostname] ||= {})[slug] = placement.to_h
        end
      end
    end
end
