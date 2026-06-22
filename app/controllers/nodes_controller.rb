class NodesController < ApplicationController
  layout "public_node"
  allow_unauthenticated_access only: [:show]

  def show
    @node = Node.find_by(id: params[:id])
    if @node.blank? || !public_node_visible?(@node)
      redirect_hidden_node
      return
    end

    if (target_path = domain_target_redirect_path(@node))
      redirect_to target_path, status: :found
      return
    end

    if @node.bridge_node?
      target = @node.resolve_target
      if target != @node && public_node_visible?(target)
        redirect_to node_path(target), status: :found
      else
        redirect_hidden_node
      end
      return
    end

    @node.build_content if @node.content.blank?
    @children = public_node_accessible_children(@node)

    @navigation_domain = navigation_domain
    @navigation_root_node = @navigation_domain&.node
    boundary_node = @navigation_root_node
    @current_host_domain_root = current_host_domain_root?
    all_ancestors = @node.self_and_ancestors.reverse
    @breadcrumbs = if boundary_node.present?
      all_ancestors.drop_while { |ancestor| ancestor != boundary_node }
    else
      all_ancestors
    end

    parent_scope = if @current_host_domain_root
      Node.where(id: boundary_node.id)
    elsif @node.parent.present?
      @node.parent.children
    elsif boundary_node.present?
      Node.where(id: boundary_node.id)
    else
      Node.roots.where(role_assignment_id: @node.role_assignment_id)
    end
    @siblings = parent_scope.order(:position, :title).select { |node| public_node_navigable?(node) }
    current_index = @siblings.index(@node)
    @previous_sibling = @siblings[current_index - 1] if current_index&.positive?
    @next_sibling = @siblings[current_index + 1] if current_index
    @parent_node = parent_navigation_node(boundary_node)
    @can_manage_public_node = creator_owner_for_node?
    set_traveler_subscription_context
  end

  private

  def redirect_hidden_node
    redirect_to root_path, alert: "Questo nodo non è pubblico o non è accessibile."
  end

  def domain_target_redirect_path(node)
    domain = target_domain_for(node)
    return nil if domain.blank?

    url_for(
      controller: "/#{domain.target_controller}",
      action: domain.target_action,
      only_path: true
    )
  rescue ActionController::UrlGenerationError
    nil
  end

  def target_domain_for(node)
    domains = node.domains.active
      .where.not(target_controller: [nil, ""])
      .where.not(target_action: [nil, ""])

    current = current_domain
    if current.present? && current.node_id == node.id && domains.exists?(id: current.id)
      return current
    end

    domains.order(primary: :desc, hostname: :asc).first
  end

  def navigation_boundary_node
    navigation_domain&.node
  end

  def navigation_domain
    ancestors_from_node = @node.self_and_ancestors.to_a
    current = current_domain

    if current&.node_id.present? && ancestors_from_node.any? { |ancestor| ancestor.id == current.node_id }
      return current
    end

    ancestor_ids_by_distance = ancestors_from_node.map(&:id)
    Domain.active.where(node_id: ancestor_ids_by_distance).includes(:node).to_a.min_by do |domain|
      ancestor_ids_by_distance.index(domain.node_id)
    end
  end

  def current_host_domain_root?
    current = current_domain
    return current.node_id == @node.id if current.present?

    @navigation_domain&.node_id == @node.id
  end

  def parent_navigation_node(boundary_node)
    return nil if @node.parent_id.blank?
    return nil if @current_host_domain_root

    parent = @node.parent
    return nil if parent.blank?
    return nil unless public_node_visible?(parent)
    return nil if boundary_node.present? && !parent.self_and_ancestors.exists?(id: boundary_node.id)

    parent
  end

  def creator_owner_for_node?
    return false unless Current.user.present?
    return false unless FlowRoles.active_role_for(Current.user) == "creator"

    Current.user.role_assignments.exists?(id: @node.role_assignment_id, role: :creator_of_worlds)
  end

  def set_traveler_subscription_context
    @traveler_subscription_domain = subscription_domain_for(@node)
    return if @traveler_subscription_domain.blank?
    return unless Current.user.present?

    profile = Current.user.profile
    @traveler_subscription = profile&.traveler_subscriptions&.active&.find_by(domain: @traveler_subscription_domain)
  end

  def subscription_domain_for(node)
    current = current_domain
    if current&.node_id.present? && node.self_and_ancestors.exists?(id: current.node_id)
      return current
    end

    return @navigation_domain if @navigation_domain&.node_id.present?

    node.domains.active.order(primary: :desc, hostname: :asc).first
  end
end
