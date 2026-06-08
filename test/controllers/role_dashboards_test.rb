require "test_helper"

class RoleDashboardsTest < ActionDispatch::IntegrationTest
  ROLE_DASHBOARDS = {
    creator: :creator_world_root_url,
    teacher: :teacher_root_url,
    tutor: :tutor_root_url,
    professional: :professional_root_url
  }.freeze

  test "assigned users can access their role dashboard" do
    ROLE_DASHBOARDS.each do |role, path_helper|
      user = create_user("#{role}-dashboard@example.com")
      user.role_assignments.create!(role: role)
      sign_in(user)

      get public_send(path_helper)

      assert_response :success
    end
  end

  test "users without assignment cannot access role dashboards" do
    ROLE_DASHBOARDS.each_with_index do |(_, path_helper), index|
      user = create_user("blocked-role-dashboard-#{index}@example.com")
      sign_in(user)

      get public_send(path_helper)

      assert_redirected_to viaggiatori_url
    end
  end

  test "superadmin can access every role dashboard" do
    user = create_user("superadmin-role-dashboards@example.com", superadmin: true)
    sign_in(user)

    ROLE_DASHBOARDS.each_value do |path_helper|
      get public_send(path_helper)

      assert_response :success
    end
  end

  private

    def create_user(email, superadmin: false)
      User.create!(
        email_address: email,
        password: "password123",
        password_confirmation: "password123",
        superadmin: superadmin
      )
    end

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
