class LineOfferCatalog
  Result = Data.define(:lines, :offers)

  LINE_ATTRIBUTES = %w[title description status settings].freeze
  OFFER_ATTRIBUTES = %w[title description status previous_purchase_mode discount_percent included_offer_slugs settings].freeze

  def self.from_config(environment = Rails.env)
    new(
      lines_config: Rails.application.config_for(:metro_lines, env: environment),
      offers_config: Rails.application.config_for(:offers, env: environment)
    )
  end

  def initialize(lines_config:, offers_config:)
    @line_definitions = lines_config.to_h.deep_stringify_keys.fetch("lines", {}).to_h
    @removed_line_slugs = Array(lines_config.to_h.deep_stringify_keys["removed_slugs"]).filter_map(&:presence)
    @offer_definitions = offers_config.to_h.deep_stringify_keys.fetch("offers", {}).to_h
    @removed_offer_slugs = Array(offers_config.to_h.deep_stringify_keys["removed_slugs"]).filter_map(&:presence)
  end

  def validate!(node_definitions: configured_node_definitions)
    node_definitions = node_definitions.to_h.deep_stringify_keys
    duplicate_removed_slugs = removed_line_slugs & line_definitions.keys
    raise ArgumentError, "Linee presenti sia nel catalogo sia in removed_slugs: #{duplicate_removed_slugs.join(', ')}" if duplicate_removed_slugs.any?
    duplicate_removed_slugs = removed_offer_slugs & offer_definitions.keys
    raise ArgumentError, "Offerte presenti sia nel catalogo sia in removed_slugs: #{duplicate_removed_slugs.join(', ')}" if duplicate_removed_slugs.any?

    validate_node_memberships!(node_definitions)
    validate_lines!(node_definitions)
    validate_offers!(node_definitions)
    detect_offer_cycles!
    true
  end

  def import!
    validate!
    lines = {}

    ActiveRecord::Base.transaction do
      Offer.where(slug: removed_offer_slugs).find_each(&:destroy!)
      MetroLine.where(slug: removed_line_slugs).find_each(&:destroy!)

      line_definitions.each do |slug, attributes|
        lines[slug] = MetroLine.find_or_initialize_by(slug:).tap do |line|
          line.assign_attributes(attributes.slice(*LINE_ATTRIBUTES))
          line.domain = Domain.find_for_host(attributes.fetch("domain_hostname")).canonical_domain_record
          line.start_node = Node.find_by!(slug: attributes.fetch("start_node_slug"))
          line.end_node = Node.find_by!(slug: attributes.fetch("end_node_slug"))
          line.station_node_ids = Array(attributes["station_node_slugs"]).map { |node_slug| Node.find_by!(slug: node_slug).id }
          line.save!
        end
      end
      lines.each_value(&:validate_route!)
      validate_offer_routes!(lines.transform_values { |line| line.ordered_nodes.map(&:slug) })

      offer_definitions.each do |slug, attributes|
        Offer.find_or_initialize_by(slug:).tap do |offer|
          # Inclusioni e sconto assenti nel catalogo vengono azzerati, così toglierli dallo YAML li toglie anche dall'offerta.
          offer.assign_attributes({ "included_offer_slugs" => [], "discount_percent" => nil }.merge(attributes.slice(*OFFER_ATTRIBUTES)))
          offer.metro_line = lines.fetch(attributes.fetch("line_slug"))
          offer.start_node = Node.find_by!(slug: attributes.fetch("start_node_slug"))
          offer.end_node = Node.find_by!(slug: attributes.fetch("end_node_slug"))
          offer.save!
        end
      end
    end

    Result.new(lines: line_definitions.size, offers: offer_definitions.size)
  end

  private

    attr_reader :line_definitions, :removed_line_slugs, :offer_definitions, :removed_offer_slugs

    def configured_node_definitions
      Rails.application.config_for(:nodes).to_h.deep_stringify_keys.fetch("nodes", {}).to_h
    end

    def validate_node_memberships!(node_definitions)
      node_definitions.each do |node_slug, attributes|
        Array(attributes["line_slugs"]).each do |line_slug|
          raise ArgumentError, "Node #{node_slug}: linea sconosciuta #{line_slug}" unless line_definitions.key?(line_slug)
        end
        Array(attributes["offer_slugs"]).each do |offer_slug|
          raise ArgumentError, "Node #{node_slug}: offerta sconosciuta #{offer_slug}" unless offer_definitions.key?(offer_slug)
        end
      end
    end

    def validate_lines!(node_definitions)
      line_definitions.each do |slug, attributes|
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
        station_slugs = Array(attributes["station_node_slugs"])
        unknown_stations = station_slugs - node_definitions.keys
        raise ArgumentError, "Linea #{slug}: stazioni sconosciute #{unknown_stations.join(', ')}" if unknown_stations.any?
      end
    end

    def validate_offers!(node_definitions)
      offer_definitions.each do |slug, attributes|
        raise ArgumentError, "Offerta #{slug}: title mancante" if attributes["title"].blank?
        line_slug = attributes["line_slug"]
        raise ArgumentError, "Offerta #{slug}: linea sconosciuta #{line_slug}" unless line_definitions.key?(line_slug)

        %w[start_node_slug end_node_slug].each do |key|
          node_slug = attributes[key]
          raise ArgumentError, "Offerta #{slug}: #{key} mancante" if node_slug.blank?
          raise ArgumentError, "Offerta #{slug}: Node sconosciuto #{node_slug}" unless node_definitions.key?(node_slug)
          next if Array(node_definitions.dig(node_slug, "offer_slugs")).include?(slug)

          raise ArgumentError, "Offerta #{slug}: il Node #{node_slug} non dichiara offer_slugs: #{slug}"
        end

        Array(attributes["included_offer_slugs"]).each do |included_slug|
          raise ArgumentError, "Offerta #{slug}: inclusione sconosciuta #{included_slug}" unless offer_definitions.key?(included_slug)
          raise ArgumentError, "Offerta #{slug}: non può includere se stessa" if included_slug == slug
        end
      end
    end

    # Un'offerta è una tratta continua della propria linea: le offerte incluse stanno sulla stessa linea
    # e dentro la tratta, e i Node che dichiarano l'offerta sono esattamente le stazioni della tratta.
    def validate_offer_routes!(ordered_slugs_by_line)
      tratte = offer_definitions.to_h do |slug, attributes|
        ordered = ordered_slugs_by_line.fetch(attributes["line_slug"])
        start_index = ordered.index(attributes["start_node_slug"])
        end_index = ordered.index(attributes["end_node_slug"])
        raise ArgumentError, "Offerta #{slug}: inizio o fine non appartengono alla linea #{attributes["line_slug"]}" unless start_index && end_index
        raise ArgumentError, "Offerta #{slug}: la fine deve venire dopo l'inizio" if end_index < start_index

        [slug, { line: attributes["line_slug"], range: start_index..end_index, stations: ordered[start_index..end_index] }]
      end

      tratte.each do |slug, tratta|
        Array(offer_definitions.dig(slug, "included_offer_slugs")).each do |included_slug|
          included = tratte.fetch(included_slug)
          raise ArgumentError, "Offerta #{slug}: l'offerta inclusa #{included_slug} appartiene a un'altra linea" if included[:line] != tratta[:line]
          next if tratta[:range].cover?(included[:range])

          raise ArgumentError, "Offerta #{slug}: l'offerta inclusa #{included_slug} esce dalla tratta"
        end

        declared = Node.where("? = ANY(offer_slugs)", slug).pluck(:slug)
        missing = tratta[:stations] - declared
        outside = declared - tratta[:stations]
        raise ArgumentError, "Offerta #{slug}: stazioni senza offer_slugs: #{missing.join(', ')}" if missing.any?
        raise ArgumentError, "Offerta #{slug}: Node fuori dalla tratta dichiarano l'offerta: #{outside.join(', ')}" if outside.any?
      end
    end

    def detect_offer_cycles!
      offer_definitions.each_key do |slug|
        visit_offer!(slug, [])
      end
    end

    def visit_offer!(slug, stack)
      raise ArgumentError, "Ciclo offerte rilevato: #{(stack + [slug]).join(' → ')}" if stack.include?(slug)

      Array(offer_definitions.dig(slug, "included_offer_slugs")).each do |included_slug|
        visit_offer!(included_slug, stack + [slug])
      end
    end
end
