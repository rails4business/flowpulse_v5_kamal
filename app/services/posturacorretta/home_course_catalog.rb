module Posturacorretta
  class HomeCourseCatalog
    COURSE_ROOT = Rails.root.join("config/data/brands/posturacorretta/courses").freeze
    PROGRAM_PATH = Rails.root.join("config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml").freeze

    def self.fetch(node_slug)
      new(node_slug).fetch
    end

    def initialize(node_slug)
      @node_slug = node_slug.to_s
    end

    def fetch
      definition = node_definitions.fetch(node_slug)
      course_key = definition["course_key"]
      program_course_key = definition["program_course_key"] || course_key
      academy_module_key = definition["academy_module_key"]
      course_data = course_key.present? ? load_yaml(course_path(course_key)).fetch("contents") : []
      course = course_data.find { |entry| entry["format"] == "course" && entry["id"] == course_key }
      course ||= {
        "id" => program_course_key || node_slug,
        "slug" => node_slug,
        "title" => definition.fetch("title"),
        "description" => definition["description"],
        "access" => "free",
        "status" => definition.fetch("status", "published")
      }

      lesson_slugs = course_data.filter_map { |entry| entry["lesson_node_slug"] }.uniq
      if course_data.any? && !lesson_slugs.one?
        raise KeyError, "Il corso #{course_key} deve riferire un solo Node lezione"
      end

      @lesson_slug = lesson_slugs.first
      lesson_definition = node_definitions[@lesson_slug]
      chapters = course_data.select do |entry|
        entry["format"] == "chapter" && entry["lesson_node_slug"] == @lesson_slug
      end.sort_by { |entry| entry.fetch("position", 0) }

      curriculum = AcademyCurriculum.load

      {
        node_slug: node_slug,
        course: course.slice("id", "slug", "title", "description", "image", "access", "status"),
        lesson: lesson_definition && {
          slug: @lesson_slug,
          title: lesson_definition.fetch("title"),
          description: lesson_definition["description"]
        },
        chapters: chapters.map { |chapter| chapter_payload(chapter, course_key) },
        program_lessons: program_lessons(program_course_key),
        centres: academy_module_key.present? ? centres(curriculum, academy_module_key) : [],
        teachers: academy_module_key.present? ? teachers(curriculum, academy_module_key) : []
      }
    end

    private

      attr_reader :node_slug

      def node_definitions
        @node_definitions ||= begin
          configured_nodes = Rails.application.config_for(:nodes).to_h.deep_stringify_keys
          (configured_nodes["nodes"] || configured_nodes).to_h.deep_stringify_keys
        end
      end

      def course_path(course_key)
        unless course_key.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
          raise ArgumentError, "course_key non valida"
        end

        COURSE_ROOT.join(course_key, "course.yml")
      end

      def chapter_payload(chapter, course_key)
        chapter.slice("id", "slug", "position", "title", "description", "access", "status").merge(
          "url" => "/posturacorretta/corsi/#{course_key}/capitoli/#{chapter.fetch('slug')}"
        )
      end

      def program_lessons(course_key)
        return [] if course_key.blank?

        program = load_yaml(PROGRAM_PATH).fetch("program")
        course = program.fetch("sections", []).flat_map { |section| section.fetch("courses", []) }
          .find { |entry| entry["key"] == course_key }

        Array(course&.fetch("lessons", [])).map do |lesson|
          lesson.slice("number", "key", "title").merge(
            "sheets" => Array(lesson["sheets"]).map { |sheet| sheet.slice("chapter_key", "title", "type") }
          )
        end
      end

      def centres(curriculum, module_key)
        curriculum.fetch("locations", {}).values.filter_map do |centre|
          next unless centre["city"] != "Online"
          next unless Array(centre["projects"]).include?("posturacorretta")
          next unless Array(centre["active_modules"]).include?(module_key)

          centre.slice("slug", "name", "city", "address", "type").merge(
            "url" => "/posturacorretta/centri/#{centre.fetch('slug')}"
          )
        end
      end

      def teachers(curriculum, module_key)
        curriculum.fetch("teachers", {}).values.filter_map do |teacher|
          next unless teacher.fetch("public", true)
          next unless teacher["status"] == "active"
          next unless Array(teacher["active_modules"]).include?(module_key)

          teacher.slice("slug", "name", "role", "profession", "city", "province", "img").merge(
            "url" => "/posturacorretta/insegnanti/#{teacher.fetch('slug')}"
          )
        end
      end

      def load_yaml(path)
        raise KeyError, "Sorgente mancante: #{path}" unless path.file?

        YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
      end
  end
end
