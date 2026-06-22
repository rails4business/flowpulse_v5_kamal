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
    FlowRoles.aside_context_for(
      active_dashboard_role,
      admin: admin_dashboard_section?(current_section)
    )
  end

  def dashboard_aside_group_label(group)
    FlowRoles.group_label(group)
  end

  def traveler_dashboard_aside_subscriptions
    return [] unless active_dashboard_role == "traveler"
    return [] unless Current.user&.profile

    TravelerSubscription.ordered_for(profile: Current.user.profile, domain: current_domain)
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
    current_section.to_sym.in?(%i[dashboard domains resources pages role_map assigned_role_map weekplan])
  end

  def resolve_dashboard_menu_path(path)
    return if path.blank?
    return public_send(path) if path.is_a?(Symbol)

    path
  end

  private

    def dashboard_menu_item(item)
      item.merge(path: resolve_dashboard_menu_path(item[:path]))
    end
end
