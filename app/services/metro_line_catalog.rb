class MetroLineCatalog
  Result = Data.define(:lines)
  ATTRIBUTES = %w[title description status settings].freeze

  def self.from_config(environment = Rails.env)
    new(Rails.application.config_for(:metro_lines, env: environment))
  end

  def initialize(config)
    config = config.to_h.deep_stringify_keys
    @definitions = config.fetch("lines", {}).to_h
    @removed_slugs = Array(config["removed_slugs"]).filter_map(&:presence)
  end

  def validate!(node_definitions: configured_node_definitions)
    duplicates = removed_slugs & definitions.keys
    raise ArgumentError, "Linee presenti sia nel catalogo sia in removed_slugs: #{duplicates.join(', ')}" if duplicates.any?

    node_definitions = node_definitions.to_h.deep_stringify_keys
    node_definitions.each do |node_slug, attributes|
      Array(attributes["line_slugs"]).each do |line_slug|
        raise ArgumentError, "Node #{node_slug}: linea sconosciuta #{line_slug}" unless definitions.key?(line_slug)
      end
    end
    definitions.each do |slug, attributes|
      raise ArgumentError, "Linea #{slug}: title mancante" if attributes["title"].blank?
      %w[domain_hostname start_node_slug end_node_slug].each do |key|
        raise ArgumentError, "Linea #{slug}: #{key} mancante" if attributes[key].blank?
      end
      %w[start_node_slug end_node_slug].each do |key|
        node_slug = attributes[key]
        raise ArgumentError, "Linea #{slug}: Node sconosciuto #{node_slug}" unless node_definitions.key?(node_slug)
        next if Array(node_definitions.dig(node_slug, "line_slugs")).include?(slug)

        raise ArgumentError, "Linea #{slug}: il Node #{node_slug} non dichiara line_slugs: #{slug}"
      end
      unknown = Array(attributes["station_node_slugs"]) - node_definitions.keys
      raise ArgumentError, "Linea #{slug}: stazioni sconosciute #{unknown.join(', ')}" if unknown.any?
    end
    true
  end

  def import!
    validate!
    lines = {}
    ActiveRecord::Base.transaction do
      MetroLine.where(slug: removed_slugs).find_each(&:destroy!)
      definitions.each do |slug, attributes|
        lines[slug] = MetroLine.find_or_initialize_by(slug:).tap do |line|
          line.assign_attributes(attributes.slice(*ATTRIBUTES))
          line.domain = Domain.find_for_host(attributes.fetch("domain_hostname")).canonical_domain_record
          line.start_node = Node.find_by!(slug: attributes.fetch("start_node_slug"))
          line.end_node = Node.find_by!(slug: attributes.fetch("end_node_slug"))
          line.station_node_slugs = Array(attributes["station_node_slugs"])
          line.save!
        end
      end
      lines.each_value(&:validate_route!)
    end
    Result.new(lines: definitions.size)
  end

  private

    attr_reader :definitions, :removed_slugs

    def configured_node_definitions
      Rails.application.config_for(:nodes).to_h.deep_stringify_keys.fetch("nodes", {}).to_h
    end
end
