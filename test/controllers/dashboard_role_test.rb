require "test_helper"

class DashboardRoleTest < ActionDispatch::IntegrationTest
  test "traveler dashboard requires authentication" do
    get viaggiatori_url

    assert_redirected_to new_session_url(return_to: viaggiatori_path)
  end

  test "user cannot activate current role without assignment" do
    user = User.create!(
      email_address: "no-teacher-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post session_url, params: { email_address: user.email_address, password: "password123" }
    patch dashboard_role_url, params: { role: "digital" }

    assert_redirected_to viaggiatori_url
    assert_equal "traveler", user.reload.active_role
  end

  test "user can activate assigned digital role" do
    user = User.create!(
      email_address: "with-digital-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Digital User")
    assignment = RoleAssignment.create!(profile: user.profile, role: :digital, parent: create_ideatore_assignment)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    patch dashboard_role_url, params: { role: "digital" }

    assert_redirected_to viaggiatori_url
    assert_equal "digital", user.reload.active_role
    assert_equal assignment, user.current_role_assignment
  end

  test "user can activate creator role and lands on creator dashboard" do
    user = User.create!(
      email_address: "with-creator-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Creator User")
    assignment = RoleAssignment.create!(profile: user.profile, role: :creator, parent: create_ideatore_assignment)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    patch dashboard_role_url, params: { role: "creator" }

    assert_redirected_to viaggiatori_url
    assert_equal "creator", user.reload.active_role
    assert_equal assignment, user.current_role_assignment
  end

  private

    def create_ideatore_assignment
      creator = User.create!(
        email_address: "dashboard-role-creator-#{SecureRandom.hex(4)}@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      creator.create_profile!(display_name: "Creator User")
      RoleAssignment.create!(profile: creator.profile, role: :ideatore)
    end
end
