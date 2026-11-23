require "digest"

# Importa i contenuti canonici dei YAML nel database:
# - brands/<node>/courses/<corso>/course.yml  → raccolte ordinate per posizione (corsi e capitoli)
# - brands/<node>/contents/<slug>/content.yml + content.md → raccolte ordinate per data (articoli, schede)
#
# Il YAML è la fonte di struttura e testo. Lo stato di pubblicazione invece è dell'ambiente:
# l'import non lo legge e non lo tocca mai, e un contenuto nuovo parte in bozza.
# L'import non cancella nulla: contenuti, pubblicazioni, contributi e legami assenti dal YAML restano.
# I legami verso altri Content (ContentLink) si scrivono come `links: { <tipo>: [<chiave>, ...] }`; quelli che
# arrivano da un Node (es. corso introduttivo → metodica) come `links_from_nodes: { <tipo>: [<slug>, ...] }`.
class ContentCatalog
  Result = Data.define(:contents, :created, :publications, :contributions, :links, :warnings)

  ROOT = Rails.root.join("config/data")
  # Decisioni dell'ambiente (piano contenuti, punto 1): restano negli impegni, non nel YAML.
  ENVIRONMENT_KEYS = %w[status visibility access].freeze
  CONTENT_KEYS = %w[
    id parent_id slug format position title description excerpt content_path
    publication_at written_on publications lesson_node_slug links links_from_nodes
  ].freeze
  PUBLICATION_KEYS = %w[key platform format url external_id title body position scheduled_at].freeze

  def initialize(root: ROOT)
    @root = Pathname(root)
  end

  def entries
    @entries ||= (course_entries + collection_entries).tap { |items| inherit_nodes!(items) }
  end

  def validate!
    errors = []
    keys = entries.map { |entry| entry.fetch(:key) }
    keys.tally.each { |key, count| errors << "chiave duplicata #{key}" if count > 1 }
    by_key = entries_by_key

    entries.each do |entry|
      label = "#{entry.fetch(:key)} (#{entry.fetch(:source)})"
      errors << "#{label}: title mancante" if entry[:title].blank?
      errors << "#{label}: slug mancante" if entry[:slug].blank?
      errors << "#{label}: format non ammesso #{entry[:format]}" unless Content::FORMATS.include?(entry[:format])
      errors << "#{label}: parent_id sconosciuto #{entry[:parent_key]}" if entry[:parent_key] && !by_key.key?(entry[:parent_key])
      errors << "#{label}: node sconosciuto #{entry[:node_slug]}" unless nodes_by_slug.key?(entry[:node_slug])
      errors << "#{label}: Markdown mancante #{entry[:body_path]}" if entry[:body_path] && !entry[:body_path].file?
      entry.fetch(:links).each do |kind, target_keys|
        errors << "#{label}: tipo di legame non valido #{kind}" unless kind.match?(/\A[a-z][a-z0-9_]*\z/)
        target_keys.each { |target_key| errors << "#{label}: legame verso chiave sconosciuta #{target_key}" unless by_key.key?(target_key) }
      end
      entry.fetch(:links_from_nodes).each do |kind, node_slugs|
        errors << "#{label}: tipo di legame non valido #{kind}" unless kind.match?(/\A[a-z][a-z0-9_]*\z/)
        node_slugs.each { |node_slug| errors << "#{label}: legame da node sconosciuto #{node_slug}" unless nodes_by_slug.key?(node_slug) }
      end
      entry.fetch(:publications).each do |publication|
        unless ContentPublication::PLATFORMS.include?(publication["platform"]) && ContentPublication::FORMATS.include?(publication["format"])
          errors << "#{label}: pubblicazione non valida #{publication.slice('platform', 'format').to_json}"
        end
      end
    end

    raise ArgumentError, "Catalogo contenuti non valido:\n- #{errors.join("\n- ")}" if errors.any?

    true
  end

  def import!(dry_run: false)
    validate!
    result = nil

    ActiveRecord::Base.transaction do
      result = import_entries!
      raise ActiveRecord::Rollback if dry_run
    end

    result
  end

  private

    attr_reader :root

    def import_entries!
      imported = {}
      created = 0
      publications = 0
      contributions = 0
      warnings = []

      entries.sort_by { |entry| depth(entry) }.each do |entry|
        content = Content.find_or_initialize_by(key: entry.fetch(:key))
        created += 1 if content.new_record?
        body = entry[:body_path]&.read
        content.assign_attributes(
          node: nodes_by_slug.fetch(entry.fetch(:node_slug)),
          parent: entry[:parent_key] && imported.fetch(entry[:parent_key]),
          slug: entry.fetch(:slug),
          format: entry.fetch(:format),
          position: entry.fetch(:position),
          title: entry.fetch(:title),
          description: entry[:description],
          body_md: body,
          source_path: entry[:body_path]&.relative_path_from(Rails.root)&.to_s,
          source_checksum: Digest::SHA256.hexdigest([body, entry.fetch(:data).to_json].join("\n")),
          data: entry.fetch(:data),
          written_on: entry[:written_on]
        )
        content.save!
        imported[entry.fetch(:key)] = content

        publications += import_publications!(content, entry.fetch(:publications))
        added, warning, author = import_author!(content, entry)
        contributions += added
        warnings << warning if warning
        assign_owner!(content, author)
      end

      links = entries.sum do |entry|
        content = imported.fetch(entry.fetch(:key))
        import_links!(content, entry.fetch(:links), imported) + import_links_from_nodes!(content, entry.fetch(:links_from_nodes))
      end

      Result.new(contents: imported.size, created:, publications:, contributions:, links:, warnings:)
    end

    # Aggiunge i legami mancanti; quelli già presenti restano, anche se tolti dal YAML.
    def import_links!(content, definitions, imported)
      definitions.sum do |kind, target_keys|
        target_keys.each_with_index.count do |target_key, index|
          link = content.outgoing_links.find_or_initialize_by(kind:, target_content: imported.fetch(target_key))
          next false unless link.new_record?

          link.update!(position: index)
        end
      end
    end

    def import_publications!(content, definitions)
      definitions.each_with_index do |definition, index|
        key = definition["key"].presence || "#{definition.fetch('platform')}-#{definition.fetch('format')}"
        publication = content.publications.find_or_initialize_by(key: key)
        publication.assign_attributes(
          platform: definition.fetch("platform"),
          format: definition.fetch("format"),
          url: definition["url"],
          external_id: definition["external_id"],
          title: definition["title"],
          body: definition["body"],
          position: definition.fetch("position", index),
          scheduled_at: definition["scheduled_at"],
          metadata: definition.except(*PUBLICATION_KEYS)
        )
        publication.save!
      end
      definitions.size
    end

    # L'autore indicato come node diventa un contributo del profilo che ha quel node come principale.
    def import_author!(content, entry)
      author_slug = entry[:author_node_slug]
      return [0, nil, nil] if author_slug.blank?

      profile = Profile.joins(:primary_node).find_by(nodes: { slug: author_slug })
      return [0, "#{entry.fetch(:key)}: nessun profilo con node principale #{author_slug}", nil] unless profile

      contribution = content.contributions.find_or_initialize_by(profile: profile, role: "autore")
      return [0, nil, profile] if contribution.persisted?

      contribution.save!
      [1, nil, profile]
    end

    # Il titolare si assegna una volta sola (poi può cambiare dall'admin): l'autore, altrimenti il titolare del
    # genitore (un capitolo senza autore è del titolare del corso).
    def assign_owner!(content, author)
      return if content.profile_id.present?

      owner_id = author&.id || content.parent&.profile_id
      content.update_column(:profile_id, owner_id) if owner_id
    end

    def course_entries
      Dir.glob(root.join("brands/*/courses/*/course.yml")).sort.flat_map do |path|
        folder_node = Pathname(path).relative_path_from(root.join("brands")).each_filename.first
        Array(load_yaml(path)["contents"]).each_with_index.map do |item, index|
          build_entry(
            item,
            source: relative(path),
            folder_node:,
            default_position: index,
            body_path: item["content_path"].present? ? root.join(item.fetch("content_path")).cleanpath : nil
          )
        end
      end
    end

    def collection_entries
      Dir.glob(root.join("brands/*/contents/*/content.yml")).sort.map do |path|
        folder_node = Pathname(path).relative_path_from(root.join("brands")).each_filename.first
        item = load_yaml(path)
        # Il testo sta in content.md accanto al YAML, oppure dove indica content_path (testi non ancora spostati).
        markdown = item["content_path"].present? ? root.join(item["content_path"]).cleanpath : Pathname(path).dirname.join("content.md")
        build_entry(
          item.reverse_merge("format" => "post"),
          source: relative(path),
          folder_node:,
          default_position: 0,
          body_path: markdown.file? ? markdown : nil
        )
      end
    end

    def build_entry(item, source:, folder_node:, default_position:, body_path:)
      item = item.to_h.deep_stringify_keys
      item = front_matter(body_path).slice("author_node_slug", "publisher_node_slug").merge(item) if body_path
      {
        key: (item["id"].presence || item["slug"]).to_s,
        parent_key: item["parent_id"].presence,
        slug: item["slug"].to_s,
        format: item["format"].to_s,
        position: Integer(item.fetch("position", default_position)),
        title: item["title"],
        description: item["description"].presence || item["excerpt"],
        written_on: parse_date(item["written_on"] || item["publication_at"]),
        node_slug: item["lesson_node_slug"].presence || item["publisher_node_slug"].presence || (item["author_node_slug"].presence unless item["parent_id"].present?),
        folder_node: folder_node,
        author_node_slug: item["author_node_slug"].presence,
        body_path: body_path,
        publications: Array(item["publications"]).map { |publication| publication.to_h.deep_stringify_keys },
        links: item["links"].to_h.transform_values { |keys| Array(keys).map(&:to_s) },
        links_from_nodes: item["links_from_nodes"].to_h.transform_values { |slugs| Array(slugs).map(&:to_s) },
        data: item.except(*CONTENT_KEYS, *ENVIRONMENT_KEYS),
        source: source
      }
    end

    # Un capitolo sta nel node della sua lezione (lesson_node_slug); senza lezione, nel node del suo corso;
    # in mancanza, nel node della cartella.
    def inherit_nodes!(items)
      by_key = items.index_by { |entry| entry.fetch(:key) }
      items.each do |entry|
        parent = by_key[entry[:parent_key]]
        entry[:node_slug] ||= parent && (parent[:node_slug] || parent[:folder_node])
        entry[:node_slug] ||= entry.fetch(:folder_node)
      end
    end

    def import_links_from_nodes!(content, definitions)
      definitions.sum do |kind, node_slugs|
        node_slugs.each_with_index.count do |node_slug, index|
          link = content.incoming_links.find_or_initialize_by(kind:, source_node: nodes_by_slug.fetch(node_slug))
          next false unless link.new_record?

          link.update!(position: index)
        end
      end
    end

    def entries_by_key
      @entries_by_key ||= entries.index_by { |entry| entry.fetch(:key) }
    end

    def depth(entry)
      by_key = entries_by_key
      level = 0
      current = entry
      while (current = by_key[current[:parent_key]])
        level += 1
        raise ArgumentError, "Catalogo contenuti: ciclo di parent_id su #{entry.fetch(:key)}" if level > by_key.size
      end
      level
    end

    def nodes_by_slug
      @nodes_by_slug ||= Node.where(slug: entries.flat_map { |entry| [ entry[:node_slug], *entry.fetch(:links_from_nodes).values.flatten ] }.uniq).index_by(&:slug)
    end

    # Molti Markdown dei capitoli dichiarano autore ed editore nell'intestazione YAML;
    # i valori del course.yml hanno la precedenza. Il corpo importato resta il file intero.
    def front_matter(path)
      return {} unless path.file?

      text = path.read
      return {} unless text.start_with?("---\n")

      YAML.safe_load(text.split(/^---\s*$/, 3)[1].to_s, permitted_classes: [Date], aliases: false).to_h
    rescue Psych::SyntaxError
      {}
    end

    def parse_date(value)
      return if value.blank?

      Date.parse(value.to_s)
    rescue Date::Error
      nil
    end

    def load_yaml(path)
      YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
    end

    def relative(path)
      Pathname(path).relative_path_from(root).to_s
    end
end
