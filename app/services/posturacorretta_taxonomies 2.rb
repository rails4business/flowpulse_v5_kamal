require "yaml"

class PosturacorrettaTaxonomies
  CONFIG_PATH = Rails.root.join("config/data/posturacorretta/taxonomies.yml")

  REQUIRED_KEYS = %w[audiences areas scopes].freeze
  REQUIRED_AUDIENCE_KEYS = %w[label short_label description color classes].freeze
  REQUIRED_AREA_KEYS = %w[
    element label short_label title meaning description imperative action color classes scopes
  ].freeze
  REQUIRED_SCOPE_KEYS = %w[title description token width color classes slug positive blockage].freeze

  def self.load(path: CONFIG_PATH)
    new(path).load
  end

  def initialize(path)
    @path = Pathname(path)
  end

  def load
    data = YAML.safe_load_file(@path, permitted_classes: [], aliases: false) || {}
    missing = REQUIRED_KEYS - data.keys
    raise ArgumentError, "Tassonomie PosturaCorretta incomplete: #{missing.join(', ')}" if missing.any?

    validate_hash!("audiences", data.fetch("audiences"), REQUIRED_AUDIENCE_KEYS)
    validate_hash!("areas", data.fetch("areas"), REQUIRED_AREA_KEYS)
    validate_hash!("scopes", data.fetch("scopes"), REQUIRED_SCOPE_KEYS)
    validate_area_scopes!(data.fetch("areas"), data.fetch("scopes").keys)
    validate_home_links!(data.fetch("home_links", []), data)

    data
  end

  private

  def validate_hash!(section_name, records, required_keys)
    raise ArgumentError, "Tassonomia #{section_name} non valida" unless records.is_a?(Hash)

    records.each do |slug, record|
      missing = required_keys - record.keys
      raise ArgumentError, "Tassonomia #{section_name}.#{slug} incompleta: #{missing.join(', ')}" if missing.any?
    end
  end

  def validate_area_scopes!(areas, scope_slugs)
    areas.each do |slug, area|
      unknown_scopes = area.fetch("scopes") - scope_slugs
      next if unknown_scopes.empty?

      raise ArgumentError, "Area tassonomia #{slug} collegata ad ambiti inesistenti: #{unknown_scopes.join(', ')}"
    end
  end

  def validate_home_links!(links, data)
    raise ArgumentError, "Tassonomia home_links non valida" unless links.is_a?(Array)

    links.each do |link|
      source = link["source"]
      next unless source

      section = source.fetch("section")
      slug = source.fetch("slug")
      records = data.fetch(section) { raise ArgumentError, "Home link collegato a sezione inesistente: #{section}" }
      next if records.key?(slug)

      raise ArgumentError, "Home link collegato a tassonomia inesistente: #{section}.#{slug}"
    end
  end
end
