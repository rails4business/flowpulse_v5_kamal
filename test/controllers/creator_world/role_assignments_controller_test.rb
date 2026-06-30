require "test_helper"

module CreatorWorld
  class RoleAssignmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @creator = create_user("creator-role-mgmt@example.com")
      @creator_ra = RoleAssignment.create!(profile: @creator.profile, role: :creator_of_worlds)
      @creator.update!(active_role: :creator)

      @other_creator = create_user("other-creator-role-mgmt@example.com")
      @other_creator_ra = RoleAssignment.create!(profile: @other_creator.profile, role: :creator_of_worlds)

      @target = create_user("target-role-mgmt@example.com")
    end

    test "creator can view role assignments index" do
      child_ra = RoleAssignment.create!(profile: @target.profile, role: :teacher, parent: @creator_ra)

      post session_url, params: { email_address: @creator.email_address, password: "password123" }
      get creator_world_role_assignments_url

      assert_response :success
      assert_includes response.body, "Gestione Ruoli"
      assert_includes response.body, @target.profile.username
      assert_includes response.body, "Teacher"
    end

    test "creator can access new role assignment form" do
      post session_url, params: { email_address: @creator.email_address, password: "password123" }
      get new_creator_world_role_assignment_url

      assert_response :success
      assert_includes response.body, "Assegna Ruolo"
      assert_includes response.body, @creator_ra.display_name
    end

    test "creator can assign child role to user with profile" do
      post session_url, params: { email_address: @creator.email_address, password: "password123" }

      assert_difference -> { RoleAssignment.count }, 1 do
        post creator_world_role_assignments_url, params: {
          role_assignment: {
            username: @target.profile.username,
            role: "teacher",
            parent_id: @creator_ra.id
          }
        }
      end

      assert_redirected_to creator_world_role_assignments_url
      assert @target.role_assignments.exists?(role: "teacher", parent_id: @creator_ra.id)
    end

    test "creator cannot assign child role to another creator's parent assignment by passing parent_id" do
      post session_url, params: { email_address: @creator.email_address, password: "password123" }

      assert_difference -> { RoleAssignment.count }, 1 do
        post creator_world_role_assignments_url, params: {
          role_assignment: {
            username: @target.profile.username,
            role: "teacher",
            parent_id: @other_creator_ra.id
          }
        }
      end

      assert_redirected_to creator_world_role_assignments_url

      assigned_role = RoleAssignment.last
      assert_equal @creator_ra.id, assigned_role.parent_id
      assert_not_equal @other_creator_ra.id, assigned_role.parent_id
    end

    test "creator cannot assign root roles" do
      post session_url, params: { email_address: @creator.email_address, password: "password123" }

      assert_no_difference -> { RoleAssignment.count } do
        post creator_world_role_assignments_url, params: {
          role_assignment: {
            username: @target.profile.username,
            role: "creator_of_worlds",
            parent_id: @creator_ra.id
          }
        }
      end

      assert_response :unprocessable_entity
    end

    test "creator can revoke child role assignment" do
      child_ra = RoleAssignment.create!(profile: @target.profile, role: :teacher, parent: @creator_ra)

      post session_url, params: { email_address: @creator.email_address, password: "password123" }

      assert_difference -> { RoleAssignment.count }, -1 do
        delete creator_world_role_assignment_url(child_ra)
      end

      assert_redirected_to creator_world_role_assignments_url
    end

    test "creator cannot revoke role assignment from another creator channel" do
      child_ra = RoleAssignment.create!(profile: @target.profile, role: :teacher, parent: @other_creator_ra)

      post session_url, params: { email_address: @creator.email_address, password: "password123" }

      assert_no_difference -> { RoleAssignment.count } do
        delete creator_world_role_assignment_url(child_ra)
        assert_response :not_found
      end
    end

    test "non-creator cannot access creator world role assignments" do
      non_creator = create_user("non-creator@example.com")
      post session_url, params: { email_address: non_creator.email_address, password: "password123" }

      get creator_world_role_assignments_url
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
        username = email.split('@').first.downcase.gsub(/[^a-z0-9_]/, '_')[0...30]
        user.create_profile!(display_name: email.split('@').first, username: username)
        user
      end
  end
end
