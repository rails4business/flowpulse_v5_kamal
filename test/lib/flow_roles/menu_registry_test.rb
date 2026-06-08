require "test_helper"

class FlowRolesMenuRegistryTest < ActiveSupport::TestCase
  test "returns menu items for active role" do
    keys = FlowRoles::MenuRegistry.visible_for(active_role: "teacher").map(&:key)

    assert_includes keys, :traveler
    assert_includes keys, :teacher
    assert_not_includes keys, :domains
  end

  test "menu items include ux metadata" do
    teacher = FlowRoles::MenuRegistry.items.find { |item| item.key == :teacher }

    assert_equal :workspace, teacher.group
    assert_equal "EDU", teacher.badge
  end

  test "superadmin sees every menu item" do
    all_keys = FlowRoles::MenuRegistry.items.map(&:key)
    visible_keys = FlowRoles::MenuRegistry.visible_for(active_role: "traveler", superadmin: true).map(&:key)

    assert_equal all_keys, visible_keys
  end
end
