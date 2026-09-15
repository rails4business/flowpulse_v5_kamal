require "test_helper"

class FlowRolesTest < ActiveSupport::TestCase
  test "exposes the new transversal roles" do
    assert_includes FlowRoles.roles, "ideatore"
    assert_includes FlowRoles.roles, "creator"
    assert_includes FlowRoles.roles, "digital"
    assert_equal "Ideatore", FlowRoles.label(:ideatore)
    assert_equal ["ideatore"], FlowRoles.assignable_roles
  end

  test "checks access from an ideatore assignment and superadmin bypass" do
    ideatore = create_user("ideatore-flow@example.com")
    RoleAssignment.create!(profile: ideatore.profile, role: :ideatore)
    superadmin = create_user("superadmin-flow@example.com", superadmin: true)

    assert FlowRoles.can_access_role?(ideatore, :ideatore)
    assert FlowRoles.can_access_role?(superadmin, :digital)
  end

  test "demo is reserved to superadmin and no longer has an active role" do
    user = create_user("member-flow@example.com")
    superadmin = create_user("superadmin-demo@example.com", superadmin: true, active_role: :superadmin)

    assert_not FlowRoles.can?(user, :show, :demo)
    assert FlowRoles.can?(superadmin, :show, :demo)
  end

  test "returns the new aside contexts" do
    assert_equal "Ideatore", FlowRoles.aside_context_for("ideatore").fetch(:title)
    assert_equal "Digital", FlowRoles.aside_context_for("digital").fetch(:title)
  end

  private

  def create_user(email, **attributes)
    user = User.create!({ email_address: email, password: "password123", password_confirmation: "password123" }.merge(attributes))
    user.create_profile!(display_name: email.split("@").first.capitalize)
    user
  end
end
