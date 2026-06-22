require "test_helper"

class FlowRolesMenuRegistryTest < ActiveSupport::TestCase
  test "returns menu items for active role" do
    keys = FlowRoles::MenuRegistry.visible_for(active_role: "teacher").map(&:key)

    assert_not_includes keys, :traveler
    assert_includes keys, :teacher
    assert_not_includes keys, :domains
  end

  test "menu items include ux metadata" do
    teacher = FlowRoles::MenuRegistry.items.find { |item| item.key == :teacher }

    assert_equal :workspace, teacher.group
    assert_equal "EDU", teacher.badge
  end

  test "superadmin menu keeps route map and includes assigned role map link" do
    role_map = FlowRoles::MenuRegistry.visible_for(active_role: "superadmin", superadmin: true).find { |menu_item| menu_item.key == :role_map }
    assigned_role_map = FlowRoles::MenuRegistry.visible_for(active_role: "superadmin", superadmin: true).find { |menu_item| menu_item.key == :assigned_role_map }

    assert_equal "Role map", role_map.title
    assert_equal :admin_role_map_path, role_map.path
    assert_equal "Assigned roles", assigned_role_map.title
    assert_equal :admin_assigned_role_map_path, assigned_role_map.path
    assert_equal %w[superadmin], assigned_role_map.roles
  end

  test "superadmin sees all menu items in superadmin mode but only traveler items in traveler mode" do
    all_keys = FlowRoles::MenuRegistry.items.map(&:key)
    visible_keys_superadmin = FlowRoles::MenuRegistry.visible_for(active_role: "superadmin", superadmin: true).map(&:key)
    visible_keys_traveler = FlowRoles::MenuRegistry.visible_for(active_role: "traveler", superadmin: true).map(&:key)

    assert_equal all_keys, visible_keys_superadmin
    assert_equal [:traveler], visible_keys_traveler
  end
end
