require "test_helper"

class RoleAssignmentTest < ActiveSupport::TestCase
  setup do
    @creator_user = User.create!(
      email_address: "creator-owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @creator_user.create_profile!(display_name: "Creator Owner")
    @creator_ra = RoleAssignment.create!(profile: @creator_user.profile, role: :creator_of_worlds)
  end

  test "role assignment with child role parent constraints" do
    user = User.create!(
      email_address: "teacher@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Teacher")

    ra = RoleAssignment.new(profile: user.profile, role: :teacher)
    assert_not ra.valid?
    assert_includes ra.errors[:parent_id], "deve essere impostato per i ruoli children"

    # Invalid: parent is not creator_of_worlds
    non_creator_ra = RoleAssignment.create!(profile: user.profile, role: :demo)
    ra.parent = non_creator_ra
    assert_not ra.valid?
    assert_includes ra.errors[:parent_id], "deve fare riferimento a un ruolo 'creator_of_worlds'"

    # Valid: parent is creator_of_worlds
    ra.parent = @creator_ra
    assert ra.valid?
  end

  test "role assignment with creator_of_worlds or demo cannot have a parent" do
    user = User.create!(
      email_address: "creator2@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Creator 2")

    ra = RoleAssignment.new(profile: user.profile, role: :creator_of_worlds, parent: @creator_ra)
    assert_not ra.valid?
    assert_includes ra.errors[:parent_id], "non può essere impostato per il ruolo creator_of_worlds"

    ra2 = RoleAssignment.new(profile: user.profile, role: :demo, parent: @creator_ra)
    assert_not ra2.valid?
    assert_includes ra2.errors[:parent_id], "non può essere impostato per il ruolo demo"
  end

  test "role assignment makes role activatable" do
    user = User.create!(
      email_address: "teacher2@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Teacher 2")

    RoleAssignment.create!(profile: user.profile, role: :teacher, parent: @creator_ra)

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
    user.create_profile!(display_name: "Unsafe")

    assert_not user.can_activate_role?("teacher")
    assert_not user.active_role_attivabile?
    assert_equal "traveler", user.safe_active_role
  end

  test "active role is valid while matching assignment exists" do
    user = User.create!(
      email_address: "safe-active-role@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :teacher
    )
    user.create_profile!(display_name: "Safe")
    assignment = RoleAssignment.create!(profile: user.profile, role: :teacher, parent: @creator_ra)

    assert user.active_role_attivabile?
    assert_equal "teacher", user.safe_active_role

    assignment.destroy!
    assert_not user.reload.active_role_attivabile?
    assert_equal "traveler", user.safe_active_role
  end

  test "superadmin can only activate traveler and superadmin without assignments" do
    user = User.create!(
      email_address: "superadmin-role@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true
    )
    user.create_profile!(display_name: "Superadmin User")

    assert_equal %w[traveler superadmin], user.ruoli_attivabili
    assert user.can_activate_role?("traveler")
    assert user.can_activate_role?("superadmin")
    assert_not user.can_activate_role?("teacher")
    assert_not user.can_activate_role?("tutor")

    # If assigned, they can also activate that role
    creator_ra = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
    assert_includes user.ruoli_attivabili, "creator"
    assert user.can_activate_role?("creator")
  end

  test "demo access role assignment adds demo active role" do
    user = User.create!(
      email_address: "demo-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Demo")
    RoleAssignment.create!(profile: user.profile, role: :demo)

    assert_includes user.ruoli_attivabili, "demo"
    assert user.has_demo_access?
  end

  test "role assignment requires a profile" do
    user = User.create!(
      email_address: "no-profile@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    ra = RoleAssignment.new(profile: user.profile, role: :creator_of_worlds)
    assert_not ra.valid?
    assert_includes ra.errors[:profile], "must exist"

    user.create_profile!(display_name: "Profile exists")
    ra.profile = user.reload.profile
    assert ra.valid?
  end
end
