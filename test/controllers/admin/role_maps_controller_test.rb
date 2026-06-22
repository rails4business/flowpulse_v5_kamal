require "test_helper"

module Admin
  class RoleMapsControllerTest < ActionDispatch::IntegrationTest
    test "superadmin can see role map" do
      user = User.create!(
        email_address: "role-map-superadmin@example.com",
        password: "password123",
        password_confirmation: "password123",
        superadmin: true,
        active_role: :superadmin
      )

      post session_url, params: { email_address: user.email_address, password: "password123" }
      get admin_role_map_url

      assert_response :success
      assert_includes response.body, "Role map"
      assert_includes response.body, "Teacher"
      assert_includes response.body, "Tutor"
      assert_includes response.body, "Risorse"
    end

    test "assigned admin cannot see role map" do
      user = User.create!(
        email_address: "role-map-admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      user.create_profile!(display_name: "Admin User")
      RoleAssignment.create!(profile: user.profile, role: :admin, parent: create_creator_assignment)

      post session_url, params: { email_address: user.email_address, password: "password123" }
      get admin_role_map_url

      assert_redirected_to viaggiatori_url
    end

    private

      def create_creator_assignment
        creator = User.create!(
          email_address: "role-map-creator-#{SecureRandom.hex(4)}@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        creator.create_profile!(display_name: "Creator User")
        RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
      end
  end
end
