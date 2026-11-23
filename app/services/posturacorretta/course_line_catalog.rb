module Posturacorretta
  class CourseLineCatalog
    GROUP_SLUG = "linee-percorso-posturacorretta"

    DEFINITIONS = [
      { slug: "inizia-con-posturacorretta", title: "Inizia con PosturaCorretta", area: "Introduzione", courses: %w[corso-introduzione-al-percorso-integrato corso-la-prima-settimana-con-posturacorretta postura-e-fisiologia] },
      { slug: "area-massaggio-terapie-manuali-tecniche-corporee", title: "Recupero e terapie manuali", area: "Espressione", courses: %w[igiene-posturale principi-di-fisioterapia biomeccanica-comportamentale-gds principi-di-osteopatia introduzione-al-metodo-corpo-e-coscienza introduzione-alla-kinesiologia-applicata altre-metodiche-posturali] },
      { slug: "area-movimento-postura-attivita-motoria", title: "Movimento e allenamento", area: "Espressione", courses: %w[rinforzo-muscolare sequenza-kinesiologia cinque-tibetani otto-pezzi-di-brocato sequenza-yoga sviluppo-movimento-bambini-dns animal-flow movimenti-arcaici capoeira tai-chi] },
      { slug: "area-mente-postura-ascolto-consapevolezza", title: "Mente, emozioni e consapevolezza", area: "Espressione", courses: %w[morfopsicologia human-design caycedo-sofrologia corso-corpo-e-coscienza yoga-nozioni-avanzate su-wen siamo-fatti-di-parole potere-delle-storie efficacia-personale viaggio-dell-eroe medicina-del-suono teatro corso-il-giardino-del-corpo bagno-di-foresta viaggio-sonoro] },
      { slug: "percorso-salute-nutrire-il-corpo", title: "Percorso salute · Nutrire il corpo", area: "Espressione", courses: %w[area-alimentazione-postura-nutrimento-fisiologia area-farmaci-postura-regolazione-medicamenti cosa-stiamo-mangiando medicina-dei-semplici cosa-e-il-cibo medicina-mediterranea cibo-viene-dalla-terra medicina-cinese cibo-e-industrializzazione ayurveda cibo-trasmettere-energia] },
      { slug: "risorse-potenzialita-imprenditorialita", title: "Risorse, potenzialità e imprenditorialità", area: "Espressione", courses: %w[corso-le-tue-risorse] }
    ].freeze

    def sync!
      brand = Node.find_by!(slug: "posturacorretta")
      group = upsert_node(slug: GROUP_SLUG, title: "Percorsi PosturaCorretta", parent: brand, view_type: "course_line_group", position: 1)

      DEFINITIONS.each_with_index do |definition, line_index|
        line = upsert_node(
          slug: definition.fetch(:slug), title: definition.fetch(:title), parent: group,
          view_type: "course_line", content_type: definition.fetch(:area), position: line_index + 1
        )
        sync_courses!(line, definition.fetch(:courses))
      end

      group
    end

    private

      def upsert_node(slug:, title:, parent:, view_type:, position:, content_type: nil)
        Node.find_or_initialize_by(slug:).tap do |node|
          node.assign_attributes(
            title:, parent:, role_assignment: parent.role_assignment, view_type:, content_type:,
            position:, status: "published", visibility: "public", node_type: :project
          )
          node.save!
        end
      end

      def sync_courses!(line, course_slugs)
        courses = Node.where(slug: course_slugs).index_by(&:slug)
        missing = course_slugs - courses.keys
        raise ActiveRecord::RecordNotFound, "Corsi mancanti per #{line.slug}: #{missing.join(', ')}" if missing.any?

        course_slugs.each_with_index do |slug, index|
          courses.fetch(slug).update!(parent: line, position: index + 1, view_type: "course")
        end
      end
  end
end
