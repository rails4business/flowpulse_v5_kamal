require "test_helper"

class FlowRolesTest < ActiveSupport::TestCase
  test "exposes roles labels and assignable roles" do
    assert_includes FlowRoles.roles, "teacher"
    assert_equal "Teacher", FlowRoles.label(:teacher)
    assert_includes FlowRoles.assignable_roles, "demo"
    assert_includes FlowRoles.assignable_roles, "creator_of_worlds"
    assert_not_includes FlowRoles.assignable_roles, "tutor"
    assert_not_includes FlowRoles.assignable_roles, "superadmin"
  end

  test "checks role access from assignments and superadmin bypass" do
    teacher = create_user("flow-roles-teacher@example.com")
    RoleAssignment.create!(profile: teacher.profile, role: :teacher, parent: create_creator_assignment)

    superadmin = create_user("flow-roles-superadmin@example.com", superadmin: true)

    assert FlowRoles.can_access_role?(teacher, :teacher)
    assert_not FlowRoles.can_access_role?(teacher, :tutor)
    assert FlowRoles.can_access_role?(superadmin, :tutor)
  end

  test "denies admin access when active role is demo" do
    user = create_user("flow-roles-demo-admin@example.com", demo_access: true, active_role: :demo)
    RoleAssignment.create!(profile: user.profile, role: :admin, parent: create_creator_assignment)

    assert_not FlowRoles.can?(user, :show, :admin)
    assert_not FlowRoles.can?(user, :update, :admin)
    assert FlowRoles.can?(user, :show, :demo)
  end

  test "groups menu items for superadmin" do
    user = create_user("flow-roles-menu-superadmin@example.com", superadmin: true)

    groups = FlowRoles.grouped_menu_for(user, active_role: "superadmin")

    assert_includes groups.keys, :workspace
    assert_includes groups.keys, :demo
    assert_includes groups.keys, :admin
    assert_includes groups.fetch(:workspace).map(&:badge), "EXP"
  end

  test "returns aside context for role and admin areas" do
    assert_equal "Didattica", FlowRoles.aside_context_for("teacher").fetch(:title)
    assert_equal "Admin", FlowRoles.aside_context_for("teacher", admin: true).fetch(:title)
    assert_equal "Superadmin", FlowRoles.aside_context_for("superadmin", admin: true).fetch(:title)
  end

  private

    def create_user(email, **attributes)
      demo_val = attributes.delete(:demo_access)
      user = User.create!(
        {
          email_address: email,
          password: "password123",
          password_confirmation: "password123"
        }.merge(attributes)
      )
      user.create_profile!(display_name: email.split("@").first.capitalize)
      RoleAssignment.create!(profile: user.profile, role: :demo) if demo_val
      user
    end

    def create_creator_assignment
      creator = create_user("creator-#{SecureRandom.hex(4)}@example.com")
      RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    end
end
