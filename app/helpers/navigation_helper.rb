# app/helpers/navigation_helper.rb
module NavigationHelper
  def verified_link_to(name = nil, path = nil, **options, &block)
    if block_given?
      path = name
      return unless can_access_path?(path)

      link_to(path, **options, &block)
    else
      return unless can_access_path?(path)

      link_to(name, path, **options)
    end
  end

  def dashboard_menu_items
    FlowRoles.menu_for(Current.user, active_role: active_dashboard_role)
      .map { |item| dashboard_menu_item(item.to_h) }
  end

  def visible_dashboard_menu_items
    FlowRoles.menu_for(Current.user, active_role: active_dashboard_role)
      .select { |item| item.path.present? }
      .map { |item| dashboard_menu_item(item.to_h) }
  end

  def dashboard_aside_menu_items(current_section)
    dashboard_aside_menu_groups(current_section).values.flatten
  end

  def dashboard_aside_menu_groups(current_section)
    contextual_builder = contextual_dashboard_builder
    if contextual_builder.applicable?
      return contextual_builder.groups.transform_values do |items|
        items.map { |item| dashboard_menu_item(item.to_h) }
      end
    end

    grouped_items = FlowRoles.grouped_menu_for(
      Current.user,
      active_role: active_dashboard_role,
      admin: admin_dashboard_section?(current_section)
    )

    grouped_items.each_with_object({}) do |(group, items), result|
      visible_items = items.select { |item| item.path.present? }
        .select { |item| can_access_menu_item?(item.to_h) }
        .map { |item| dashboard_menu_item(item.to_h) }

      result[group] = visible_items if visible_items.any?
    end
  end

  def dashboard_aside_context(current_section)
    contextual_builder = contextual_dashboard_builder
    return contextual_builder.heading if contextual_builder.applicable?

    FlowRoles.aside_context_for(
      active_dashboard_role,
      admin: admin_dashboard_section?(current_section)
    )
  end

  def dashboard_aside_group_label(group)
    FlowRoles.group_label(group)
  end

  def traveler_dashboard_aside_brand_accesses
    return [] if contextual_dashboard_builder.applicable?
    return [] unless active_dashboard_role == "traveler"
    return [] unless Current.user&.profile

    BrandAccess.ordered_for(profile: Current.user.profile, domain: current_domain)
  end

  def can_access_menu_item?(item)
    item.fetch(:roles).include?(active_dashboard_role)
  end

  def can_access_path?(path)
    path = path.to_s

    return true if FlowRoles.can?(Current.user, :read, :public) && public_path?(path)
    return FlowRoles.can?(Current.user, :read, :demo) if demo_path?(path)

    if admin_path?(path)
      return FlowRoles.can?(Current.user, :read, :domains) if path.start_with?("/admin/domains")
      return FlowRoles.can?(Current.user, :read, :role_map) if path.start_with?("/admin/role_map")
      return FlowRoles.can?(Current.user, :read, :assigned_role_map) if path.start_with?("/admin/assigned_role_map")
      return FlowRoles.can?(Current.user, :read, :superadmin) if path.start_with?("/admin/elenco_pagine")
      return FlowRoles.can?(Current.user, :read, :superadmin) if path.start_with?("/admin/appunti")
      return FlowRoles.can?(Current.user, :read, :superadmin) if path.start_with?("/admin/contenuti")

      return FlowRoles.can?(Current.user, :read, :admin)
    end

    false
  end

  def public_path?(path)
    !path.start_with?("/admin", "/demo")
  end

  def admin_path?(path)
    path.start_with?("/admin")
  end

  def demo_path?(path)
    path.start_with?("/demo")
  end

  def admin_dashboard_section?(current_section)
    current_section.to_sym.in?(%i[brands dashboard domains resources pages notes content_taxonomy role_map assigned_role_map password_reset_requests data_commitment_imports weekplan])
  end

  def resolve_dashboard_menu_path(path)
    return if path.blank?
    return public_send(path) if path.is_a?(Symbol)

    path
  end

  def canonical_flowpulse_admin_dashboard_url
    return local_domain_admin_dashboard_path(admin_brand_slug: "flowpulse") if local_request?

    admin_dashboard_url(host: "flowpulse.net", protocol: "https")
  end

  def dashboard_navigation_link_to(path, **options, &block)
    if contextual_dashboard_builder.applicable?
      link_to(path, **options, &block)
    else
      verified_link_to(path, **options, &block)
    end
  end

  def dashboard_entry_path
    paths = dashboard_navigation_paths
    DashboardNavigation::Policy.new(context: dashboard_access_context).allowed?(:dashboard) ? paths.dashboard : paths.home
  end

  def dashboard_navigation_active?(item, current_section)
    return current_section == item[:key] unless contextual_dashboard_builder.applicable?
    return request.path == item[:path] if item[:key] == :brand_home
    return current_section == item[:key] unless item[:key] == :brand_dashboard

    if DashboardNavigation::Policy.new(context: dashboard_access_context).platform?
      controller_path.start_with?("admin/")
    else
      controller_path.start_with?("brands/admin/") || controller_path.in?(%w[
        brands/genera_impresa_projects brands/genera_impresa_people brands/genera_impresa_brand_people
      ])
    end
  end

  def dashboard_navigation_paths
    prefix = local_request? || (current_domain&.resolved_node.nil? && dashboard_access_context.brand.present? && dashboard_access_context.brand.slug != "flowpulse")
    DashboardNavigation::Paths.new(context: dashboard_access_context, local: prefix)
  end

  def dashboard_available_domains
    return Domain.active.order(:hostname) if dashboard_access_context.superadmin?

    brand_ids = Current.user&.profile&.brand_accesses&.active&.select(:brand_node_id)
    domain_ids = [dashboard_access_context.domain&.id].compact
    scope = brand_ids ? Domain.active.where(node_id: brand_ids) : Domain.none
    scope.or(Domain.active.where(id: domain_ids)).order(:hostname)
  end

  private

    def contextual_dashboard_builder
      DashboardAside::Builder.new(context: dashboard_access_context,
        paths: dashboard_navigation_paths)
    end

    def dashboard_menu_item(item)
      item.merge(path: resolve_dashboard_menu_path(item[:path]))
    end
end
