module Posturacorretta
  # Corsi e capitoli di PosturaCorretta letti dai Content importati da
  # config/data/brands/posturacorretta/courses (bin/rails contents:import).
  # Restituisce gli stessi hash del vecchio catalogo YAML, così pagine e viste non cambiano.
  class ContentRepository
    NODE_SLUG = "posturacorretta".freeze
    FORMATS = %w[course chapter].freeze
    CANONICAL_COURSES_ROOT = Rails.root.join("config/data/brands/posturacorretta/courses").freeze
    DATA_ROOT = "config/data/".freeze
    # Fase 2a del piano contenuti: finché lo stato visibile non passa al Content,
    # status, visibility e access si leggono ancora dai course.yml.
    ENVIRONMENT_KEYS = %w[status visibility access].freeze

    def initialize(include_scheduled: false)
      @include_scheduled = include_scheduled
    end

    def courses
      contents.select { |content| content.fetch("format") == "course" }.map { |course| hydrate_course(course) }
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

    attr_reader :include_scheduled

    # Già in ordine di posizione e, a parità, di chiave (uguale in ogni ambiente).
    def contents
      @contents ||= records.map { |record| to_item(record) }.select { |content| visible?(content) }
    end

    def records
      Content.joins(:node).where(nodes: { slug: NODE_SLUG }, format: FORMATS).includes(:parent).order(:position, :key)
    end

    def to_item(record)
      record.data.merge(
        "id" => record.key,
        "parent_id" => record.parent&.key,
        "format" => record.format,
        "slug" => record.slug,
        "position" => record.position,
        "title" => record.title,
        "description" => record.description,
        "content_path" => record.source_path&.delete_prefix(DATA_ROOT)
      ).merge(environment_values.fetch(record.key, {})).compact
    end

    def environment_values
      @environment_values ||= Dir.glob(CANONICAL_COURSES_ROOT.join("*", "course.yml")).sort.flat_map do |course_path|
        YAML.safe_load_file(course_path, permitted_classes: [], aliases: false).to_h.fetch("contents", [])
      end.to_h { |item| [item.fetch("id"), item.slice(*ENVIRONMENT_KEYS)] }
    end

    def visible?(content)
      status = content.fetch("status", "draft")
      return true if include_scheduled
      return true if status == "published"
      return false unless status == "scheduled" && content["published_at"].present?

      Time.zone.parse(content.fetch("published_at")) <= Time.current
    end

    def by_id
      @by_id ||= contents.index_by { |content| content.fetch("id") }
    end

    def hydrate_course(course)
      course.merge("chapters" => contents.select { |content| content.fetch("parent_id", nil) == course.fetch("id") })
    end
  end
end
