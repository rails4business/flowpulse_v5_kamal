require "test_helper"

class RoleAssignmentTest < ActiveSupport::TestCase
  test "global role assignment makes role activatable" do
    user = User.create!(
      email_address: "teacher@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    user.role_assignments.create!(role: :teacher)

    assert_includes user.ruoli_attivabili, "traveler"
    assert_includes user.ruoli_attivabili, "teacher"
    assert user.can_activate_role?("teacher")
    assert user.teacher_user?
  end

  test "active role falls back when matching role assignment is missing" do
    user = User.create!(
      email_address: "unsafe-active-role@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :teacher
    )

    assert_not user.can_activate_role?("teacher")
    assert_not user.active_role_attivabile?
    assert_equal "traveler", user.safe_active_role
  end

  test "active role is valid while matching global assignment exists" do
    user = User.create!(
      email_address: "safe-active-role@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :teacher
    )
    assignment = user.role_assignments.create!(role: :teacher)

    assert user.active_role_attivabile?
    assert_equal "teacher", user.safe_active_role

    assignment.destroy!
    assert_not user.reload.active_role_attivabile?
    assert_equal "traveler", user.safe_active_role
  end

  test "context role assignment does not become a global active role" do
    user = User.create!(
      email_address: "creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    domain = Domain.create!(
      hostname: "creator-world.test",
      target_controller: "landing",
      target_action: "flowpulse",
      locale: "it"
    )

    user.role_assignments.create!(role: :creator, context: domain)

    assert_not_includes user.ruoli_attivabili, "creator"
    assert user.creator_user?(domain)
    assert_not user.creator_user?
  end

  test "superadmin can activate every switchable role without assignments" do
    user = User.create!(
      email_address: "superadmin-role@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true
    )

    assert_equal User::SWITCHABLE_ROLES, user.ruoli_attivabili
    assert user.can_activate_role?("teacher")
    assert user.can_activate_role?("tutor")
  end

  test "demo access adds demo active role without role assignment" do
    user = User.create!(
      email_address: "demo-role@example.com",
      password: "password123",
      password_confirmation: "password123",
      demo_access: true
    )

    assert_includes user.ruoli_attivabili, "demo"
    assert user.has_demo_access?
  end
end
