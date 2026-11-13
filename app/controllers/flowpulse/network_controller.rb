module Flowpulse
  class NetworkController < ApplicationController
    layout "landing"
    allow_unauthenticated_access only: %i[global automatic lanes]

    def global
      @catalog_editor_enabled = NodeCatalogEditor.enabled?
      @network_nodes = Node.published_public
        .includes(:parent, :children, :link_node, :professional_owner_node, :domains)
        .order(:title, :id)
      @manageable_role_assignment_ids = if Current.user&.superadmin_user?
        @network_nodes.map(&:role_assignment_id).uniq
      else
        []
      end
    end

    def automatic
      if params[:legacy_centrality] && params[:node].present?
        mode = params[:modalita] == "all" ? "all" : "only"
        query = request.query_parameters.symbolize_keys.except(:node, :modalita)
        return redirect_to flowpulse_automatic_network_node_path(mode, params[:node], **query), status: :moved_permanently
      end

      @automatic_center = params[:modalita] != "all"
      global
      render :global
    end

    def lanes
      nodes = Node.published_public
        .includes(:parent, :link_node, :domains)
        .order(:position, :title, :id)
        .to_a
      hidden_view_types = %w[access_bridge backlink_bridge methodology_preview]
      @lane_mode = params[:vista] == "professional" ? "professional" : "brand"
      visible_nodes = nodes.reject { |node| hidden_view_types.include?(node.view_type) }
        .select { |node| @lane_mode == "professional" ? node.professional? : node.project? }
      visible_ids = visible_nodes.map(&:id).to_set
      nodes_by_id = nodes.index_by(&:id)

      @lane_nodes = visible_nodes.map do |node|
        domains = node.domains.select(&:active?).sort_by(&:display_hostname)
        {
          id: node.id,
          parent_id: node.parent_id,
          slug: node.slug,
          title: node.title,
          description: node.description.to_s,
          color: effective_lane_color(node, nodes_by_id),
          domains: domains.map(&:display_hostname),
          has_domain: domains.any?,
          lane_container: node.lane_column?,
          position: node.position,
          node_type: node.node_type,
          domain_owner_id: lane_domain_owner_id(node, nodes_by_id),
          url: node_path(node)
        }
      end

      @lane_relations = visible_nodes.filter_map do |node|
        next if node.parent_id.blank? || !visible_ids.include?(node.parent_id)

        { source: node.parent_id, target: node.id, kind: "Gerarchia" }
      end

      @lane_relations.concat(nodes.filter_map do |node|
        next if node.link_node_id.blank? || !visible_ids.include?(node.link_node_id)

        source = hidden_view_types.include?(node.view_type) ? node.parent : node
        next if source.blank? || !visible_ids.include?(source.id) || source.id == node.link_node_id

        { source: source.id, target: node.link_node_id, kind: "Ponte" }
      end)
      @lane_relations.uniq!

      @lane_domains = visible_nodes.select { |node| node.domains.any?(&:active?) }
        .sort_by { |node| [node.title.downcase, node.id] }
      @lane_selected = @lane_domains.find { |node| node.slug == params[:node] } ||
        visible_nodes.find { |node| node.slug == params[:node] } ||
        @lane_domains.first || visible_nodes.first
      requested_open_slugs = params[:corsie].to_s.split(",").map(&:strip).reject(&:blank?).uniq
      valid_container_slugs = visible_nodes.select(&:lane_column?).map(&:slug).to_set
      @lane_open_slugs = requested_open_slugs.select { |slug| valid_container_slugs.include?(slug) }
      if params[:node].blank? && @lane_selected.present?
        return redirect_to flowpulse_network_lanes_path(@lane_selected.slug, **request.query_parameters.symbolize_keys)
      end
    end

    def destroy_node
      node = Node.find(params[:id])
      unless can_manage_node?(node)
        return redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: "Non hai i permessi per eliminare questo Node."
      end
      if node.domains.exists?
        return redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: "Un Brand con dominio non può essere eliminato dalla mappa."
      end
      if node.children.exists?
        return redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: "Prima di eliminare il Node devi ricollocare o eliminare i suoi figli."
      end

      if node.destroy
        redirect_to flowpulse_global_network_path(vista: params[:vista]), notice: "Node #{node.title} eliminato. Ricorda di aggiornare il catalogo YAML."
      else
        redirect_to flowpulse_global_network_path(node: node.slug, vista: params[:vista]), alert: node.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotDestroyed => error
      redirect_to flowpulse_global_network_path(node: node&.slug, vista: params[:vista]), alert: error.record.errors.full_messages.to_sentence
    end

    def show
      @professional_brands = professional_brands
      @owned_brands = owned_project_brands
      group_owned_brands
      @administered_brands = contextual_brands_for(%w[admin responsabile]) - @owned_brands
      @collaboration_assignments = collaboration_assignments.reject do |assignment|
        (@owned_brands + @administered_brands).include?(assignment.context)
      end
    end

    private

      def effective_lane_color(node, nodes_by_id)
        current = node
        visited = Set.new
        while current && !visited.include?(current.id)
          return current.map_color.upcase if current.map_color.present?

          visited << current.id
          current = nodes_by_id[current.parent_id]
        end
        "#64748B"
      end

      def lane_domain_owner_id(node, nodes_by_id)
        current = node
        visited = Set.new
        while current && !visited.include?(current.id)
          return current.id if current.domains.any?(&:active?)

          visited << current.id
          current = nodes_by_id[current.parent_id]
        end
        nil
      end

      def can_manage_node?(node)
        return false if Current.user.blank?
        return true if Current.user.superadmin_user?

        Current.user.role_assignments.ideatore.exists?(id: node.role_assignment_id)
      end

      def professional_brands
        @professional_brands ||= Node.professional.joins(:domains)
          .where("nodes.role_assignment_id IN (?) OR nodes.id = ?", owner_role_assignment_ids, current_profile.primary_node_id)
          .distinct.preload(:domains).order(:title, :id).to_a
      end

      def owned_project_brands
        professional_ids = professional_brands.map(&:id)
        Node.project.joins(:domains)
          .where("nodes.role_assignment_id IN (:role_ids) OR nodes.professional_owner_node_id IN (:professional_ids)",
            role_ids: owner_role_assignment_ids.presence || [0], professional_ids: professional_ids.presence || [0])
          .distinct.preload(:domains).order(:title, :id).to_a
      end

      def contextual_brands_for(roles)
        current_profile.role_assignments.includes(context: :domains)
          .where(role: roles, context_type: "Node")
          .filter_map { |assignment| assignment.context if assignment.context&.brand? }
          .uniq.sort_by { |node| [node.title, node.id] }
      end

      def collaboration_assignments
        current_profile.role_assignments.includes(context: :domains)
          .where(role: :operator, context_type: "Node")
          .select { |assignment| assignment.context&.brand? }
          .sort_by { |assignment| [assignment.context.title, assignment.id] }
      end

      def group_owned_brands
        @owned_brands_by_professional_id = Hash.new { |hash, key| hash[key] = [] }
        @unassigned_owned_brands = []

        @owned_brands.each do |brand|
          professional = @professional_brands.find { |candidate| candidate.id == brand.professional_owner_node_id }
          if professional.blank?
            matching = @professional_brands.select { |candidate| candidate.role_assignment_id == brand.role_assignment_id }
            professional = matching.one? ? matching.first : nil
          end

          if professional
            @owned_brands_by_professional_id[professional.id] << brand
          else
            @unassigned_owned_brands << brand
          end
        end
      end

      def owner_role_assignment_ids
        @owner_role_assignment_ids ||= current_profile.role_assignments.where(role: :ideatore).pluck(:id)
      end
  end
end
