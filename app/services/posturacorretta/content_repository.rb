module Posturacorretta
  # Corsi e capitoli di PosturaCorretta letti dai Content importati da
  # config/data/brands/posturacorretta/courses (bin/rails contents:import).
  # Restituisce gli stessi hash del vecchio catalogo YAML, così pagine e viste non cambiano.
  class ContentRepository
    NODE_SLUG = "posturacorretta".freeze
    FORMATS = %w[course chapter].freeze
    DATA_ROOT = "config/data/".freeze

    # status, visibility e access sono lo stato di pubblicazione del Content in questo ambiente,
    # deciso dall'ultimo impegno di pubblicazione concluso (mai dal YAML).
    # include_scheduled: true mostra anche le bozze, per titoli e struttura in preparazione.
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
        "content_path" => record.source_path&.delete_prefix(DATA_ROOT),
        "status" => record.publication_status,
        "visibility" => record.publication_visibility,
        "access" => access_for(record)
      ).compact
    end

    # Le viste conoscono solo libero o a pagamento; senza una decisione il contenuto resta libero.
    def access_for(record)
      record.access_modes.empty? || record.access_modes.include?("free") ? "free" : "paid"
    end

    def visible?(content)
      include_scheduled || content.fetch("status") == "published"
    end

    def by_id
      @by_id ||= contents.index_by { |content| content.fetch("id") }
    end

    def hydrate_course(course)
      course.merge("chapters" => contents.select { |content| content.fetch("parent_id", nil) == course.fetch("id") })
    end
  end
end
