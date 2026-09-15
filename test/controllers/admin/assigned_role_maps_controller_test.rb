require "test_helper"

module Admin
  class AssignedRoleMapsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @superadmin = create_user("assigned-role-map-superadmin@example.com", superadmin: true)
      @superadmin.update!(active_role: :superadmin)
      @ideatore = create_user("assigned-role-map-ideatore@example.com")
      @ideatore_assignment = RoleAssignment.create!(profile: @ideatore.profile, role: :ideatore)
      @brand = Node.create!(title: "Brand operatori", role_assignment: @ideatore_assignment, operator_roles: %w[insegnante segreteria])
      Domain.create!(hostname: "brand-operatori.test", locale: "it", node: @brand, active: true)
      @target = create_user("assigned-role-map-target@example.com")
    end

    test "superadmin sees operator function in the assigned role map" do
      RoleAssignment.create!(profile: @target.profile, role: :operator, role_operator: "insegnante", context: @brand, parent: @ideatore_assignment)

      sign_in(@superadmin)
      get admin_assigned_role_map_url

      assert_response :success
      assert_includes response.body, "Funzione"
      assert_includes response.body, "Insegnante"
      assert_includes response.body, "Brand operatori"
    end

    test "superadmin assigns an operator using a configured brand function" do
      sign_in(@superadmin)

      assert_difference -> { @target.role_assignments.reload.count }, 1 do
        post admin_assigned_role_map_url, params: {
          role_assignment: {
            user_identifier: @target.email_address,
            role: "operator",
            brand_id: @brand.id,
            role_operator: "insegnante"
          }
        }
      end

      assert_redirected_to admin_assigned_role_map_url
      assignment = @target.role_assignments.find_by!(role: :operator, role_operator: "insegnante")
      assert_equal @brand, assignment.context
      assert_equal @ideatore_assignment, assignment.parent
    end

    test "superadmin cannot assign an operator function outside the brand list" do
      sign_in(@superadmin)

      assert_no_difference -> { @target.role_assignments.reload.count } do
        post admin_assigned_role_map_url, params: {
          role_assignment: {
            user_identifier: @target.email_address,
            role: "operator",
            brand_id: @brand.id,
            role_operator: "professionista"
          }
        }
      end

      assert_response :unprocessable_entity
      assert_includes response.body, "non è previsto per questo Brand"
    end

    private

      def sign_in(user)
        post session_url, params: { email_address: user.email_address, password: "password123" }
      end

      def create_user(email, **attributes)
        user = User.create!({ email_address: email, password: "password123", password_confirmation: "password123" }.merge(attributes))
        user.create_profile!(display_name: email.split("@").first, username: email.split("@").first.tr("-", "_")[0...30])
        user
      end
  end
end
