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
    user.role_assignments.create!(role: :teacher)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    patch dashboard_role_url, params: { role: "teacher" }

    assert_redirected_to teacher_root_url
    assert_equal "teacher", user.reload.active_role
  end
end
