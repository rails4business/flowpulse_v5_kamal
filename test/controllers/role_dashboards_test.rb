require "test_helper"

class RoleDashboardsTest < ActionDispatch::IntegrationTest
  test "retired role dashboards are not accessible to a traveler" do
    user = User.create!(
      email_address: "retired-role-dashboards@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Traveler")
    post session_url, params: { email_address: user.email_address, password: "password123" }

    [teacher_root_url, tutor_root_url, professional_root_url].each do |url|
      get url

      assert_redirected_to viaggiatori_url
    end
  end

  test "an ideatore can access the current Brand dashboard" do
    user = User.create!(
      email_address: "ideatore-dashboard@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :ideatore
    )
    user.create_profile!(display_name: "Ideatore")
    assignment = RoleAssignment.create!(profile: user.profile, role: :ideatore)
    user.update!(current_role_assignment: assignment)
    post session_url, params: { email_address: user.email_address, password: "password123" }

    get creator_world_root_url

    assert_response :success
  end
end
