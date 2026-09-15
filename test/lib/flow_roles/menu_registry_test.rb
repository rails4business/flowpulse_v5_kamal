require "test_helper"

class FlowRolesMenuRegistryTest < ActiveSupport::TestCase
  test "ideatore receives the ideatore workspace entry" do
    keys = FlowRoles::MenuRegistry.visible_for(active_role: "ideatore").map(&:key)

    assert_includes keys, :ideatore
    assert_not_includes keys, :teacher
    assert_not_includes keys, :domains
  end

  test "ideatore item includes ux metadata" do
    ideatore = FlowRoles::MenuRegistry.items.find { |item| item.key == :ideatore }

    assert_equal :workspace, ideatore.group
    assert_equal "CR", ideatore.badge
  end

  test "superadmin menu keeps the technical dashboard and not a duplicate brand link" do
    items = FlowRoles::MenuRegistry.visible_for(active_role: "superadmin", superadmin: true)
    dashboard = items.find { |item| item.key == :dashboard }

    assert_equal "Dashboard Admin", dashboard.title
    assert_equal :admin_dashboard_path, dashboard.path
    assert_not_includes items.map(&:key), :brands
  end
end
