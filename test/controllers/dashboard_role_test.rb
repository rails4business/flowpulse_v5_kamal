require "test_helper"

class DashboardRoleTest < ActionDispatch::IntegrationTest
  test "traveler dashboard requires authentication" do
    get viaggiatori_url

    assert_redirected_to new_session_url
  end

  test "user cannot activate role without assignment" do
    user = User.create!(
      email_address: "no-teacher-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post session_url, params: { email_address: user.email_address, password: "password123" }
    patch dashboard_role_url, params: { role: "teacher" }

    assert_redirected_to viaggiatori_url
    assert_equal "traveler", user.reload.active_role
  end

  test "user can activate assigned role" do
    user = User.create!(
      email_address: "with-teacher-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Teacher User")
    RoleAssignment.create!(profile: user.profile, role: :teacher, parent: create_creator_assignment)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    patch dashboard_role_url, params: { role: "teacher" }

    assert_redirected_to teacher_root_url
    assert_equal "teacher", user.reload.active_role
  end

  test "user can activate creator role and lands on creator dashboard" do
    user = User.create!(
      email_address: "with-creator-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Creator User")
    assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    patch dashboard_role_url, params: { role: "creator" }

    assert_redirected_to creator_world_root_url
    assert_equal "creator", user.reload.active_role
    assert_equal assignment, user.current_role_assignment
  end

  private

    def create_creator_assignment
      creator = User.create!(
        email_address: "dashboard-role-creator-#{SecureRandom.hex(4)}@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      creator.create_profile!(display_name: "Creator User")
      RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    end
end
