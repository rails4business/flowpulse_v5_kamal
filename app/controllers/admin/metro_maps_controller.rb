module Admin
  class MetroMapsController < BaseController
    layout "landing"

    before_action :require_superadmin!

    HIDDEN_BRIDGE_TYPES = %w[access_bridge backlink_bridge methodology_preview].freeze

    def show
      @domain = Domain.find_for_host(params[:hostname])
      raise ActiveRecord::RecordNotFound, "Dominio non trovato" unless @domain&.active?

      @domain = @domain.canonical_domain_record
      @root_node = @domain.resolved_node
      raise ActiveRecord::RecordNotFound, "Il dominio non ha un Node associato" unless @root_node

      @domains = Domain.active
        .where(canonical_host: [nil, ""])
        .where.not(node_id: nil)
        .includes(:node)
        .order(:hostname)

      @metro_map = MetroMap.includes(:placements).find_by(domain: @domain)
      @metro_lines = MetroLine.where(domain: @domain).includes(:start_node, :end_node).order(:title)
      @offers = Offer.where(metro_line: @metro_lines).order(:title)
      @bridges = @root_node.self_and_descendants.where(view_type: HIDDEN_BRIDGE_TYPES).where.not(link_node_id: nil).includes(:parent, :link_node).order(:title)
      @metro_graph = build_graph
    end

    def create_bridge
      domain = selected_domain
      source = internal_nodes(domain).find(params[:source_node_id])
      target = allowed_nodes(domain).find(params[:target_node_id])
      raise ArgumentError, "Origine e destinazione devono essere diverse" if source == target
      if source.children.where(link_node: target, view_type: HIDDEN_BRIDGE_TYPES).exists?
        raise ArgumentError, "Questo ponte esiste già"
      end

      bridge = Node.create!(
        role_assignment: source.role_assignment,
        parent: source,
        link_node: target,
        title: "Ponte #{source.title} → #{target.title}",
        slug: unique_bridge_slug(source, target),
        view_type: "access_bridge",
        status: "published",
        visibility: "public"
      )
      write_node_catalog_entries([bridge])
      redirect_to flowpulse_metro_map_path(hostname: domain.display_hostname), notice: "Ponte creato."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError => error
      redirect_to flowpulse_metro_map_path(hostname: params[:hostname]), alert: error.message
    end

    def create_node
      domain = selected_domain
      parent = internal_nodes(domain).find(params[:parent_node_id])
      node = Node.create!(
        role_assignment: parent.role_assignment,
        parent:,
        title: params[:title].to_s.strip,
        slug: params[:slug].to_s.strip.parameterize.presence,
        description: params[:description].to_s.strip.presence,
        node_type: "project",
        view_type: "default",
        status: "published",
        visibility: "public",
        map_color: params[:map_color].presence
      )
      write_node_catalog_entries([node])
      redirect_to flowpulse_metro_map_path(hostname: domain.display_hostname), notice: "Node #{node.title} creato."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
      redirect_to flowpulse_metro_map_path(hostname: params[:hostname]), alert: error.message
    end

    def destroy_bridge
      domain = selected_domain
      bridge = domain.resolved_node.self_and_descendants.where(view_type: HIDDEN_BRIDGE_TYPES).where.not(link_node_id: nil).find(params[:id])
      bridge.destroy!
      delete_node_catalog_entry(bridge.slug)
      redirect_to flowpulse_metro_map_path(hostname: domain.display_hostname), notice: "Ponte eliminato."
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotDestroyed => error
      redirect_to flowpulse_metro_map_path(hostname: params[:hostname]), alert: error.message
    end

    def update_parent
      domain = selected_domain
      node = internal_nodes(domain).find(params[:node_id])
      new_parent = internal_nodes(domain).find(params[:parent_node_id])
      raise ArgumentError, "La radice del dominio non può essere spostata" if node == domain.resolved_node
      raise ArgumentError, "Un Node non può essere genitore di se stesso" if node == new_parent
      raise ArgumentError, "Il nuovo genitore è un discendente del Node" if node.self_and_descendants.exists?(id: new_parent.id)
      raise ArgumentError, "Un Node ponte non può essere genitore" if new_parent.bridge_node?

      node.update!(parent: new_parent)
      write_node_catalog_entries([node])
      redirect_to flowpulse_metro_map_path(hostname: domain.display_hostname), notice: "#{node.title} spostato sotto #{new_parent.title}."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError => error
      redirect_to flowpulse_metro_map_path(hostname: params[:hostname]), alert: error.message
    end

    def create_line
      domain = selected_domain
      node_ids = ordered_node_ids(params[:station_node_ids])
      nodes = allowed_nodes(domain).where(id: node_ids).index_by(&:id).values_at(*node_ids).compact
      raise ArgumentError, "Seleziona almeno due stazioni valide" if nodes.size < 2 || nodes.size != node_ids.size

      line = MetroLine.new(
        domain:,
        slug: params[:slug].to_s.parameterize,
        title: params[:title].to_s.strip,
        description: params[:description].to_s.strip.presence,
        start_node: nodes.first,
        end_node: nodes.last,
        station_node_ids: nodes.map(&:id),
        status: "draft"
      )
      changed_nodes = []
      MetroLine.transaction do
        nodes.each do |node|
          node.update!(line_slugs: (node.line_slugs + [line.slug]).uniq)
          changed_nodes << node
        end
        line.save!
        line.validate_route!
      end
      write_node_catalog_entries(changed_nodes)
      redirect_to flowpulse_metro_map_path(hostname: domain.display_hostname), notice: "Linea #{line.title} creata. Esporta i cataloghi YAML prima del deploy."
    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      redirect_to flowpulse_metro_map_path(hostname: params[:hostname]), alert: error.message
    end

    def create_offer
      domain = selected_domain
      line = MetroLine.where(domain:).find(params[:metro_line_id])
      ordered = line.ordered_nodes
      start_node = ordered.find { |node| node.id == params[:start_node_id].to_i }
      end_node = ordered.find { |node| node.id == params[:end_node_id].to_i }
      raise ArgumentError, "Inizio o fine non appartengono alla linea" unless start_node && end_node
      start_index = ordered.index(start_node)
      end_index = ordered.index(end_node)
      raise ArgumentError, "La fine deve venire dopo l'inizio" if end_index < start_index

      included = Array(params[:included_offer_slugs]).filter_map(&:presence)
      valid_included = Offer.where(metro_line: line, slug: included).pluck(:slug)
      raise ArgumentError, "Una delle offerte incluse non appartiene alla linea" unless included.sort == valid_included.sort
      Offer.where(metro_line: line, slug: included).includes(:start_node, :end_node).each do |included_offer|
        next if (start_index..end_index).cover?(ordered.index(included_offer.start_node)..ordered.index(included_offer.end_node))

        raise ArgumentError, "L'offerta inclusa #{included_offer.title} esce dalla tratta"
      end

      offer = Offer.new(
        metro_line: line,
        slug: params[:slug].to_s.parameterize,
        title: params[:title].to_s.strip,
        description: params[:description].to_s.strip.presence,
        start_node:,
        end_node:,
        included_offer_slugs: included,
        previous_purchase_mode: params[:previous_purchase_mode],
        discount_percent: params[:discount_percent].presence,
        status: "draft"
      )
      changed_nodes = ordered[start_index..end_index]
      Offer.transaction do
        offer.save!
        changed_nodes.each { |node| node.update!(offer_slugs: (node.offer_slugs + [offer.slug]).uniq) }
      end
      write_node_catalog_entries(changed_nodes)
      redirect_to flowpulse_metro_map_path(hostname: domain.display_hostname), notice: "Offerta #{offer.title} creata. Esporta i cataloghi YAML prima del deploy."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError => error
      redirect_to flowpulse_metro_map_path(hostname: params[:hostname]), alert: error.message
    end

    def export_catalog
      domain = selected_domain
      data, filename = case params[:catalog]
      when "map"
        MetroMap.find_or_create_by!(domain:) { |record| record.title = "Metropolitana #{domain.display_hostname}" }
        [MetroCatalogExporter.maps_yaml, "metro_maps.yml"]
      when "lines"
        [MetroCatalogExporter.lines_yaml, "metro_lines.yml"]
      when "offers"
        [MetroCatalogExporter.offers_yaml, "offers.yml"]
      when "nodes"
        [MetroCatalogExporter.nodes_yaml, "nodes.yml"]
      else
        raise ActiveRecord::RecordNotFound
      end
      send_data data, filename:, type: "application/x-yaml", disposition: "attachment"
    end

    def update_positions
      domain = Domain.find_for_host(params[:hostname])&.canonical_domain_record
      raise ActiveRecord::RecordNotFound, "Dominio non trovato" unless domain&.active? && domain.resolved_node

      metro_map = MetroMap.find_or_create_by!(domain:) do |map|
        map.title = "Metropolitana #{domain.display_hostname}"
      end
      domain_nodes = domain.resolved_node.self_and_descendants
      allowed_node_ids = domain_nodes.pluck(:id).to_set
      allowed_node_ids.merge(domain_nodes.where.not(link_node_id: nil).pluck(:link_node_id))
      positions = Array(params[:positions])
      MetroMapPlacement.transaction do
        positions.each do |position|
          node_id = position[:node_id].to_i
          next unless allowed_node_ids.include?(node_id)

          metro_map.placements.find_or_initialize_by(node_id:).update!(
            x: Float(position[:x]),
            y: Float(position[:y]),
            collapsed: ActiveModel::Type::Boolean.new.cast(position[:collapsed])
          )
        end
      end
      render json: { saved: positions.size }
    rescue ArgumentError, TypeError
      render json: { error: "Coordinate non valide" }, status: :unprocessable_entity
    end

    private

      def selected_domain
        domain = Domain.find_for_host(params[:hostname])&.canonical_domain_record
        raise ActiveRecord::RecordNotFound, "Dominio non trovato" unless domain&.active? && domain.resolved_node
        domain
      end

      def allowed_nodes(domain)
        descendants = domain.resolved_node.self_and_descendants
        ids = descendants.pluck(:id)
        ids.concat(descendants.where.not(link_node_id: nil).pluck(:link_node_id))
        Node.where(id: ids.uniq)
      end

      def internal_nodes(domain)
        domain.resolved_node.self_and_descendants.where.not(view_type: HIDDEN_BRIDGE_TYPES)
      end

      def unique_bridge_slug(source, target)
        base = "ponte-#{source.slug}-#{target.slug}".truncate(90, omission: "")
        slug = base
        suffix = 2
        while Node.exists?(slug:)
          slug = "#{base}-#{suffix}"
          suffix += 1
        end
        slug
      end

      def ordered_node_ids(value)
        value.to_s.split(",").filter_map { |id| Integer(id, exception: false) }.uniq
      end

      def write_node_catalog_entries(nodes)
        return unless NodeCatalogEditor.enabled?
        return if Rails.env.test?
        nodes.each { |node| NodeCatalogEntryWriter.new(node).write! }
      end

      def delete_node_catalog_entry(slug)
        return unless NodeCatalogEditor.enabled?
        return if Rails.env.test?
        NodeCatalogEntryWriter.delete!(slug)
      end

      def build_graph
        placements_by_node_id = @metro_map ? @metro_map.placements.index_by(&:node_id) : {}
        descendants = @root_node.self_and_descendants
          .includes(:parent, :link_node, :domains)
          .order(:depth, :position, :title, :id)
          .to_a
        nodes_by_id = descendants.index_by(&:id)
        domain_node_ids = Node.joins(:domains).merge(Domain.active).distinct.pluck(:id).to_set
        owner_by_id = descendants.each_with_object({}) do |node, owners|
          current = node
          current = nodes_by_id[current.parent_id] while current && !domain_node_ids.include?(current.id)
          owners[node.id] = current&.id
        end

        visible_internal = descendants.reject { |node| HIDDEN_BRIDGE_TYPES.include?(node.view_type) }
          .select { |node| owner_by_id[node.id] == @root_node.id }
        nested_domain_roots = descendants.select do |node|
          domain_node_ids.include?(node.id) && node.id != @root_node.id && owner_by_id[node.id] == node.id
        end
        visible_nodes = (visible_internal + nested_domain_roots).uniq
        visible_ids = visible_nodes.map(&:id).to_set

        bridge_relations = descendants.filter_map do |node|
          next if node.link_node_id.blank?
          next unless owner_by_id[node.id] == @root_node.id

          source = HIDDEN_BRIDGE_TYPES.include?(node.view_type) ? node.parent : node
          next unless source && visible_ids.include?(source.id)
          next if source.id == node.link_node_id

          target = node.link_node
          next unless target

          visible_nodes << target unless visible_ids.include?(target.id)
          visible_ids << target.id
          { source: source.id, target: target.id, kind: "bridge" }
        end

        hierarchy_relations = visible_nodes.filter_map do |node|
          next unless node.parent_id && visible_ids.include?(node.parent_id)
          internal_child = owner_by_id[node.id] == @root_node.id
          nested_domain_boundary = domain_node_ids.include?(node.id) && owner_by_id[node.id] == node.id
          next unless internal_child || nested_domain_boundary

          { source: node.parent_id, target: node.id, kind: "hierarchy" }
        end

        elements = visible_nodes.uniq.map do |node|
          placement = placements_by_node_id[node.id]
          owner_id = owner_by_id[node.id]
          internal = owner_id == @root_node.id
          domains = node.domains.select(&:active?).map(&:display_hostname).sort
          destination_domain = internal ? nil : destination_domain_for(node)
          {
            data: {
              id: "node-#{node.id}",
              nodeId: node.id,
              slug: node.slug,
              label: node.title,
              color: effective_color(node, nodes_by_id),
              internal: internal,
              root: node.id == @root_node.id,
              domain: domains.first,
              domains: domains,
              nodeType: node.node_type,
              viewType: node.view_type,
              laneContainer: node.lane_container?,
              position: node.position,
              savedX: placement&.x,
              savedY: placement&.y,
              collapsed: placement&.collapsed? || false,
              url: node_path(node),
              editUrl: edit_node_path(node, return_to: request.fullpath),
              terminal: !internal,
              destinationDomain: destination_domain&.display_hostname,
              metroUrl: destination_domain && flowpulse_metro_map_path(hostname: destination_domain.display_hostname)
            }
          }
        end

        (hierarchy_relations + bridge_relations).uniq.each_with_index do |relation, index|
          source_node = visible_nodes.find { |node| node.id == relation[:source] }
          elements << {
            data: {
              id: "edge-#{relation[:kind]}-#{relation[:source]}-#{relation[:target]}-#{index}",
              source: "node-#{relation[:source]}",
              target: "node-#{relation[:target]}",
              kind: relation[:kind],
              color: relation[:kind] == "bridge" ? "#7C3AED" : effective_color(source_node, nodes_by_id)
            }
          }
        end

        {
          elements: elements,
          lines: metro_lines_graph(nodes_by_id),
          grid: MetroMapCatalog.grid_for(@domain.display_hostname),
          root_id: "node-#{@root_node.id}",
          domain: @domain.display_hostname,
          station_count: elements.count { |element| element.dig(:data, :nodeId).present? },
          connection_count: hierarchy_relations.size + bridge_relations.size
        }
      end

      def metro_lines_graph(nodes_by_id)
        offers_by_line_id = @offers.group_by(&:metro_line_id)
        @metro_lines.filter_map do |line|
          station_ids = line.ordered_nodes.map(&:id)
          offers = offers_by_line_id.fetch(line.id, [])
          titles_by_slug = offers.to_h { |offer| [offer.slug, offer.title] }
          {
            slug: line.slug,
            title: line.title,
            status: line.status,
            color: line.settings.to_h["color"].presence || effective_color(line.start_node, nodes_by_id),
            stationIds: station_ids.map { |id| "node-#{id}" },
            offers: offers.sort_by { |offer| [station_ids.index(offer.end_node_id).to_i, offer.title] }.map do |offer|
              {
                slug: offer.slug,
                title: offer.title,
                status: offer.status,
                startIndex: station_ids.index(offer.start_node_id),
                endIndex: station_ids.index(offer.end_node_id),
                includes: offer.included_offer_slugs.map { |slug| titles_by_slug[slug] || slug },
                previousPurchaseMode: offer.previous_purchase_mode,
                discountPercent: offer.discount_percent
              }
            end
          }
        rescue MetroLine::InvalidRoute
          nil
        end
      end

      def effective_color(node, nodes_by_id)
        current = node
        visited = Set.new
        while current && !visited.include?(current.id)
          return current.map_color.upcase if current.map_color.present?

          visited << current.id
          current = nodes_by_id[current.parent_id]
        end
        "#2563EB"
      end

      def destination_domain_for(node)
        site_node = node.site_node
        return unless site_node

        site_node.primary_domain&.canonical_domain_record ||
          site_node.domains.active.where(canonical_host: [nil, ""]).order(primary: :desc).order(:hostname).first&.canonical_domain_record
      end
  end
end
