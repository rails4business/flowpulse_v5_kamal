module Posturacorretta
  class ContentRepository
    ALLOWED_FORMATS = %w[course chapter].freeze
    ALLOWED_ACCESS = %w[free paid].freeze
    CANONICAL_COURSES_ROOT = Rails.root.join("config/data/brands/posturacorretta/courses").freeze

    def initialize(path: Rails.root.join("config/data/posturacorretta/contenuti/contents.yml"), include_scheduled: false)
      @path = path
      @include_scheduled = include_scheduled
    end

    def courses
      contents.select { |content| content.fetch("format") == "course" }
        .sort_by { |content| content.fetch("position", 0) }
        .map { |course| hydrate_course(course) }
    end

    def course_by_id(content_id)
      course = by_id[content_id]
      return unless course&.fetch("format") == "course"

      hydrate_course(course)
    end

    def course_by_slug(slug)
      course = contents.find { |content| content.fetch("format") == "course" && content.fetch("slug") == slug }
      hydrate_course(course) if course
    end

    private

    attr_reader :path, :include_scheduled

    def data
      @data ||= YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
    end

    def contents
      @contents ||= begin
        items = merge_canonical_courses(data.fetch("contents"))
        validate!(items)
        items.map(&:deep_stringify_keys).select { |content| visible?(content) }
      end
    end

    def visible?(content)
      return true if include_scheduled
      return false unless content.fetch("status", "published") == "published"
      return true if content["published_at"].blank?

      Time.zone.parse(content.fetch("published_at")) <= Time.current
    end

    # Durante la migrazione il catalogo storico continua a contenere tutti i
    # corsi. Un course.yml sotto il Brand sostituisce soltanto le voci con gli
    # stessi id, permettendo di migrare un corso alla volta senza duplicarlo.
    def merge_canonical_courses(legacy_items)
      canonical_items = Dir.glob(CANONICAL_COURSES_ROOT.join("*", "course.yml")).sort.flat_map do |course_path|
        YAML.safe_load_file(course_path, permitted_classes: [], aliases: false).to_h.fetch("contents", [])
      end
      overrides = canonical_items.index_by { |item| item.fetch("id") }

      legacy_items.map { |item| overrides.delete(item.fetch("id")) || item } + overrides.values
    end

    def by_id
      @by_id ||= contents.index_by { |content| content.fetch("id") }
    end

    def hydrate_course(course)
      course.merge(
        "chapters" => contents
          .select { |content| content.fetch("parent_id", nil) == course.fetch("id") }
          .sort_by { |content| content.fetch("position", 0) }
      )
    end

    def validate!(items)
      raise KeyError, "contents deve essere un elenco" unless items.is_a?(Array)

      normalized = items.map(&:deep_stringify_keys)
      ids = normalized.map { |content| content.fetch("id") }
      duplicate_ids = ids.tally.select { |_id, count| count > 1 }.keys
      raise KeyError, "Content id duplicati: #{duplicate_ids.join(', ')}" if duplicate_ids.any?

      normalized.each do |content|
        format = content.fetch("format")
        raise KeyError, "Content format non valido: #{format}" unless format.in?(ALLOWED_FORMATS)
        access = content.fetch("access")
        raise KeyError, "Content access non valido: #{access}" unless access.in?(ALLOWED_ACCESS)

        parent_id = content["parent_id"]
        if format == "course" && parent_id.present?
          raise KeyError, "Un course non può avere parent_id: #{content.fetch('id')}"
        end
        next unless format == "chapter"

        raise KeyError, "Chapter senza parent_id: #{content.fetch('id')}" if parent_id.blank?
        parent = normalized.find { |candidate| candidate.fetch("id") == parent_id }
        unless parent&.fetch("format") == "course"
          raise KeyError, "Il parent di #{content.fetch('id')} deve essere un course"
        end
      end
    end
  end
end
