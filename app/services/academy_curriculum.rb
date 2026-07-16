require "yaml"

class AcademyCurriculum
  CONFIG_PATH = Rails.root.join("config/data/posturacorretta/accademia/academy.yml")
  CONTENT_ROOT = Rails.root.join("config/data/posturacorretta/accademia")
  TEACHERS_FILENAME = "teachers.yml"
  CENTERS_FILENAME = "centers.yml"
  METHODOLOGIES_PATH = Rails.root.join("config/data/posturacorretta/metodiche/metodiche.yml")

  REQUIRED_MODULE_KEYS = %w[
    number slug title description participants modes teachers locations lessons
  ].freeze
  REQUIRED_PATH_KEYS = %w[slug title description areas].freeze
  REQUIRED_AREA_KEYS = %w[slug title description modules].freeze
  REQUIRED_LESSON_KEYS = %w[number slug title description content_path].freeze
  REQUIRED_TEACHER_KEYS = %w[slug name role category category_label img date active_modules city province].freeze
  REQUIRED_CENTER_KEYS = %w[slug name city type active_modules].freeze

  def self.load(path: CONFIG_PATH)
    new(path).load
  end

  def initialize(path)
    @path = Pathname(path)
    @directory = @path.dirname
  end

  def load
    data = load_yaml(@path)
    data["teachers"] = load_yaml(@directory.join(TEACHERS_FILENAME)).fetch("teachers", {})
    data["locations"] = load_yaml(@directory.join(CENTERS_FILENAME)).fetch("centers", {})
    data["methodologies"] = load_yaml(METHODOLOGIES_PATH).fetch("methodologies", []).index_by { |methodology| methodology.fetch("slug") }
    attach_module_relations!(data)
    attach_paths!(data)
    validate!(data)
    data
  end

  private

  def load_yaml(path)
    YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
  end

  def validate!(data)
    modules = data["modules"]
    raise ArgumentError, "config/academy.yml deve contenere modules" unless modules.is_a?(Array)

    module_slugs = modules.map { |academy_module| academy_module["slug"] }
    validate_related_records!(data.fetch("teachers"), REQUIRED_TEACHER_KEYS, module_slugs, "insegnante")
    validate_related_records!(data.fetch("locations"), REQUIRED_CENTER_KEYS, module_slugs, "centro")
    validate_paths!(data.fetch("paths", []), module_slugs)
    validate_module_methodologies!(modules, data.fetch("methodologies", {}))

    modules.each do |academy_module|
      missing = REQUIRED_MODULE_KEYS - academy_module.keys
      raise ArgumentError, "Modulo academy incompleto: #{missing.join(', ')}" if missing.any?

      lessons = academy_module["lessons"]
      raise ArgumentError, "Il modulo #{academy_module['slug']} deve contenere lessons" unless lessons.is_a?(Array)

      lessons.each do |lesson|
        missing = REQUIRED_LESSON_KEYS - lesson.keys
        raise ArgumentError, "Lezione academy incompleta: #{missing.join(', ')}" if missing.any?

        validate_content_path!(lesson["content_path"])
      end
    end
  end

  def validate_related_records!(records, required_keys, module_slugs, label)
    raise ArgumentError, "Archivio #{label} academy non valido" unless records.is_a?(Hash)

    records.each do |slug, record|
      missing = required_keys - record.keys
      raise ArgumentError, "#{label.capitalize} academy incompleto #{slug}: #{missing.join(', ')}" if missing.any?
      raise ArgumentError, "#{label.capitalize} academy con slug non coerente: #{slug}" unless record["slug"] == slug

      unknown_modules = record.fetch("active_modules") - module_slugs
      raise ArgumentError, "#{label.capitalize} academy #{slug} collegato a moduli inesistenti: #{unknown_modules.join(', ')}" if unknown_modules.any?
    end
  end

  def attach_module_relations!(data)
    modules = data.fetch("modules", [])
    teachers = data.fetch("teachers", {})
    locations = data.fetch("locations", {})

    modules.each do |academy_module|
      module_slug = academy_module.fetch("slug")
      academy_module["teachers"] = teachers.select { |_slug, teacher| teacher.fetch("active_modules", []).include?(module_slug) }.keys
      academy_module["locations"] = locations.select { |_slug, location| location.fetch("active_modules", []).include?(module_slug) }.keys
    end
  end

  def attach_paths!(data)
    modules_by_slug = data.fetch("modules", []).index_by { |academy_module| academy_module.fetch("slug") }
    data["paths"] = default_paths(modules_by_slug.keys) unless data["paths"].is_a?(Array)

    data.fetch("paths").each do |path|
      path.fetch("areas", []).each do |area|
        module_slugs = area.fetch("modules", [])
        area["module_slugs"] = module_slugs
        area["modules"] = module_slugs.filter_map do |module_slug|
          academy_module = modules_by_slug[module_slug]
          next unless academy_module

          academy_module.merge(
            "_path_slug" => path.fetch("slug"),
            "_path_title" => path.fetch("title"),
            "_area_slug" => area.fetch("slug"),
            "_area_title" => area.fetch("title")
          )
        end
      end
    end
  end

  def validate_paths!(paths, module_slugs)
    raise ArgumentError, "config/academy.yml deve contenere paths" unless paths.is_a?(Array)

    paths.each do |path|
      missing = REQUIRED_PATH_KEYS - path.keys
      raise ArgumentError, "Percorso academy incompleto: #{missing.join(', ')}" if missing.any?

      areas = path.fetch("areas")
      raise ArgumentError, "Il percorso #{path['slug']} deve contenere areas" unless areas.is_a?(Array)

      areas.each do |area|
        missing = REQUIRED_AREA_KEYS - area.keys
        raise ArgumentError, "Area academy incompleta: #{missing.join(', ')}" if missing.any?

        unknown_modules = area.fetch("module_slugs", []) - module_slugs
        raise ArgumentError, "Area academy #{area['slug']} collegata a moduli inesistenti: #{unknown_modules.join(', ')}" if unknown_modules.any?
      end
    end
  end

  def validate_module_methodologies!(modules, methodologies)
    methodology_slugs = methodologies.keys

    modules.each do |academy_module|
      unknown_methodologies = academy_module.fetch("methodologies", []) - methodology_slugs
      if unknown_methodologies.any?
        raise ArgumentError, "Modulo academy #{academy_module.fetch('slug')} collegato a metodiche inesistenti: #{unknown_methodologies.join(', ')}"
      end
    end
  end

  def default_paths(module_slugs)
    [
      {
        "slug" => "postura-e-fisiologia",
        "title" => "Postura e fisiologia",
        "description" => "Percorso principale dell'accademia.",
        "areas" => [
          {
            "slug" => "recupero",
            "title" => "Recupero",
            "description" => "Area principale del percorso.",
            "modules" => module_slugs
          }
        ]
      }
    ]
  end

  def validate_content_path!(content_path)
    full_path = CONTENT_ROOT.join(content_path.to_s).cleanpath
    unless full_path.to_s.start_with?(CONTENT_ROOT.to_s)
      raise ArgumentError, "content_path academy non valido: #{content_path}"
    end

    raise ArgumentError, "File markdown academy mancante: #{content_path}" unless full_path.file?
  end
end
