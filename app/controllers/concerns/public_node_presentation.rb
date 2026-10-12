module PublicNodePresentation
  extend ActiveSupport::Concern

  private
    def prepare_public_node(node, navigation_domain: nil, domain_root: nil)
      @node = node
      @node.build_content if @node.content.blank?
      @children = public_node_accessible_children(@node)

      @navigation_domain = navigation_domain || public_node_navigation_domain(@node)
      @navigation_root_node = @navigation_domain&.node
      boundary_node = @navigation_root_node
      @current_host_domain_root = domain_root.nil? ? public_node_domain_root?(@node) : domain_root

      all_ancestors = @node.self_and_ancestors.reverse
      @breadcrumbs = if boundary_node.present?
        all_ancestors.drop_while { |ancestor| ancestor != boundary_node }
      else
        all_ancestors
      end

      parent_scope = public_node_parent_scope(boundary_node)
      @siblings = parent_scope.order(:position, :title).select { |candidate| public_node_navigable?(candidate) }
      current_index = @siblings.index(@node)
      @previous_sibling = @siblings[current_index - 1] if current_index&.positive?
      @next_sibling = @siblings[current_index + 1] if current_index
      @parent_node = public_node_parent_navigation_node(boundary_node)
      @can_manage_public_node = public_node_creator_owner?
      set_public_node_brand_access_context
    end

    def public_node_navigation_domain(node)
      ancestors = node.self_and_ancestors.to_a
      current = current_domain

      if current&.node_id.present? && ancestors.any? { |ancestor| ancestor.id == current.node_id }
        return current
      end

      ancestor_ids = ancestors.map(&:id)
      Domain.active.where(node_id: ancestor_ids).includes(:node).to_a.min_by do |domain|
        ancestor_ids.index(domain.node_id)
      end
    end

    def public_node_domain_root?(node)
      current = current_domain
      return current.node_id == node.id if current.present?

      @navigation_domain&.node_id == node.id
    end

    def public_node_parent_scope(boundary_node)
      if @current_host_domain_root
        Node.where(id: boundary_node&.id || @node.id)
      elsif @node.parent.present?
        @node.parent.children
      elsif boundary_node.present?
        Node.where(id: boundary_node.id)
      else
        Node.roots.where(role_assignment_id: @node.role_assignment_id)
      end
    end

    def public_node_parent_navigation_node(boundary_node)
      return nil if @node.parent_id.blank? || @current_host_domain_root

      parent = @node.parent
      return nil if parent.blank? || !public_node_visible?(parent)
      return nil if boundary_node.present? && !parent.self_and_ancestors.exists?(id: boundary_node.id)

      parent
    end

    def public_node_creator_owner?
      return false unless Current.user.present?
      return false unless FlowRoles.active_role_for(Current.user) == "ideatore"

      Current.user.role_assignments.exists?(id: @node.role_assignment_id, role: :ideatore)
    end

    def set_public_node_brand_access_context
      @brand_access_domain = public_node_brand_access_domain(@node)
      return if @brand_access_domain.blank? || Current.user.blank?

      @brand_access = Current.user.profile&.brand_accesses&.active&.find_by(brand_node_id: @brand_access_domain.node_id)
    end

    def public_node_brand_access_domain(node)
      current = current_domain
      if current&.node_id.present? && node.self_and_ancestors.exists?(id: current.node_id)
        return current
      end

      return @navigation_domain if @navigation_domain&.node_id.present?

      node.domains.active.order(primary: :desc, hostname: :asc).first
    end
end
