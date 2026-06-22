require "test_helper"

module Admin
  class AssignedRoleMapsControllerTest < ActionDispatch::IntegrationTest
    test "superadmin can see assigned role map" do
      superadmin = create_user("assigned-role-map-superadmin@example.com", superadmin: true)
      superadmin.update!(active_role: :superadmin)
      teacher = create_user("assigned-role-map-teacher@example.com")
      RoleAssignment.create!(profile: teacher.profile, role: :teacher, parent: create_creator_assignment)

      post session_url, params: { email_address: superadmin.email_address, password: "password123" }
      get admin_assigned_role_map_url

      assert_response :success
      assert_includes response.body, "Assigned roles"
      assert_includes response.body, admin_new_assigned_role_map_path
      assert_includes response.body, "assigned-role-map-teacher@example.com"
      assert_includes response.body, "Teacher"
    end

    test "superadmin can open new assigned role form" do
      superadmin = create_user("assigned-role-map-new-superadmin@example.com", superadmin: true)
      superadmin.update!(active_role: :superadmin)
      create_user("assigned-role-map-new-target@example.com")

      post session_url, params: { email_address: superadmin.email_address, password: "password123" }
      get admin_new_assigned_role_map_url

      assert_response :success
      assert_includes response.body, "New assigned role"
      assert_includes response.body, "Creator of worlds"
      assert_includes response.body, "Demo"
      assert_not_includes response.body, "Teacher"
    end

    test "superadmin can create root role assignment" do
      superadmin = create_user("assigned-role-map-create-superadmin@example.com", superadmin: true)
      superadmin.update!(active_role: :superadmin)
      target = create_user("assigned-role-map-create-target@example.com")

      post session_url, params: { email_address: superadmin.email_address, password: "password123" }

      assert_difference -> { target.role_assignments.reload.count }, 1 do
        post admin_assigned_role_map_url, params: {
          role_assignment: {
            user_email: target.email_address,
            role: "creator_of_worlds"
          }
        }
      end

      assert_redirected_to admin_assigned_role_map_url
      assert target.role_assignments.exists?(role: "creator_of_worlds")
    end

    test "superadmin cannot create child role from assigned roles form" do
      superadmin = create_user("assigned-role-map-child-superadmin@example.com", superadmin: true)
      superadmin.update!(active_role: :superadmin)
      target = create_user("assigned-role-map-child-target@example.com")

      post session_url, params: { email_address: superadmin.email_address, password: "password123" }

      assert_no_difference -> { target.role_assignments.reload.count } do
        post admin_assigned_role_map_url, params: {
          role_assignment: {
            user_email: target.email_address,
            role: "teacher"
          }
        }
      end

      assert_response :unprocessable_entity
    end

    test "superadmin cannot assign creator_of_worlds to a user without a profile" do
      superadmin = create_user("assigned-role-map-invalid-superadmin@example.com", superadmin: true)
      superadmin.update!(active_role: :superadmin)
      target = create_user("assigned-role-map-invalid-target@example.com")
      target.profile.destroy!
      target.reload

      post session_url, params: { email_address: superadmin.email_address, password: "password123" }

      assert_no_difference -> { RoleAssignment.count } do
        post admin_assigned_role_map_url, params: {
          role_assignment: {
            user_email: target.email_address,
            role: "creator_of_worlds"
          }
        }
      end

      assert_response :unprocessable_entity
      assert_includes response.body, "deve avere un profilo configurato prima di poter essere assegnato"
    end

    test "assigned admin cannot see assigned role map" do
      user = create_user("assigned-role-map-admin@example.com")
      RoleAssignment.create!(profile: user.profile, role: :admin, parent: create_creator_assignment)

      post session_url, params: { email_address: user.email_address, password: "password123" }
      get admin_assigned_role_map_url

      assert_redirected_to viaggiatori_url
    end

    private

      def create_user(email, **attributes)
        user = User.create!(
          {
            email_address: email,
            password: "password123",
            password_confirmation: "password123"
          }.merge(attributes)
        )
        user.create_profile!(display_name: email.split('@').first)
        user
      end

      def create_creator_assignment
        creator = create_user("assigned-role-map-creator-#{SecureRandom.hex(4)}@example.com")
        RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
      end
  end
end
