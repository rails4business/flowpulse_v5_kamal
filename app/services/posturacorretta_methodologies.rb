require "yaml"

class PosturacorrettaMethodologies
  CONFIG_PATH = Rails.root.join("config/data/posturacorretta/metodiche/metodiche.yml")
  PROFESSIONALS_PATH = Rails.root.join("config/data/posturacorretta/metodiche/professionisti.yml")
  SCHOOLS_PATH = Rails.root.join("config/data/posturacorretta/metodiche/scuole.yml")
  CONTENT_ROOT = Rails.root.join("config/data/posturacorretta/metodiche")

  REQUIRED_METHODOLOGY_KEYS = %w[
    slug title founder founder_image_url short_description badge logo_url website_url content_path
  ].freeze
  REQUIRED_PROFESSIONAL_KEYS = %w[
    slug first_name last_name profession badge city province latitude longitude methodologies
  ].freeze
  REQUIRED_SCHOOL_KEYS = %w[
    slug name description methodologies fixed_location address city province latitude longitude website_url
  ].freeze

  def self.load
    new.load
  end

  def load
    methodologies = load_yaml(CONFIG_PATH).fetch("methodologies", [])
    professionals = load_yaml(PROFESSIONALS_PATH).fetch("professionals", [])
    schools = load_yaml(SCHOOLS_PATH).fetch("schools", [])
    validate!(methodologies, professionals, schools)

    {
      "methodologies" => methodologies,
      "methodologies_by_slug" => methodologies.index_by { |methodology| methodology.fetch("slug") },
      "professionals" => professionals,
      "schools" => schools
    }
  end

  private

  def load_yaml(path)
    YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
  end

  def validate!(methodologies, professionals, schools)
    raise ArgumentError, "metodiche.yml deve contenere methodologies" unless methodologies.is_a?(Array)
    raise ArgumentError, "professionisti.yml deve contenere professionals" unless professionals.is_a?(Array)
    raise ArgumentError, "scuole.yml deve contenere schools" unless schools.is_a?(Array)

    methodology_slugs = methodologies.map { |methodology| methodology["slug"] }

    methodologies.each do |methodology|
      missing = REQUIRED_METHODOLOGY_KEYS - methodology.keys
      raise ArgumentError, "Metodica incompleta: #{missing.join(', ')}" if missing.any?

      validate_content_path!(methodology.fetch("content_path"))
    end

    professionals.each do |professional|
      missing = REQUIRED_PROFESSIONAL_KEYS - professional.keys
      raise ArgumentError, "Professionista metodica incompleto: #{missing.join(', ')}" if missing.any?

      validate_methodology_references!(professional, methodology_slugs, "Professionista")
    end

    schools.each do |school|
      missing = REQUIRED_SCHOOL_KEYS - school.keys
      raise ArgumentError, "Scuola metodica incompleta: #{missing.join(', ')}" if missing.any?

      validate_methodology_references!(school, methodology_slugs, "Scuola")
    end
  end

  def validate_methodology_references!(record, methodology_slugs, label)
    unknown_methodologies = record.fetch("methodologies") - methodology_slugs
    return if unknown_methodologies.empty?

    raise ArgumentError, "#{label} #{record.fetch('slug')} collegato a metodiche inesistenti: #{unknown_methodologies.join(', ')}"
  end

  def validate_content_path!(content_path)
    full_path = CONTENT_ROOT.join(content_path.to_s).cleanpath
    unless full_path.to_s.start_with?(CONTENT_ROOT.to_s)
      raise ArgumentError, "content_path metodica non valido: #{content_path}"
    end

    raise ArgumentError, "File markdown metodica mancante: #{content_path}" unless full_path.file?
  end
end
