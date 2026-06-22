require "test_helper"

module CreatorWorld
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "creator dashboard shows assigned root nodes and domains" do
      user = create_user("creator-dashboard-content@example.com")
      assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
      root_node = Node.create!(title: "Postura Root", role_assignment: assignment)
      Domain.create!(hostname: "posturacorretta.test", node: root_node, locale: "it")
      user.update!(active_role: :creator, current_role_assignment: assignment)

      sign_in(user)
      get creator_world_root_url

      assert_response :success
      assert_includes response.body, "Root node e domini"
      assert_includes response.body, "Postura Root"
      assert_includes response.body, "posturacorretta.test"
      assert_includes response.body, "New root node"
      assert_not_includes response.body, "Dashboard Canale"
      assert_not_includes response.body, "Alberi Nodi"
    end

    test "creator dashboard aside only shows creator workspace link" do
      user = create_user("creator-dashboard-aside@example.com")
      assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
      user.update!(active_role: :creator, current_role_assignment: assignment)

      sign_in(user)
      get creator_world_root_url

      assert_response :success
      assert_includes response.body, "Creator"
      assert_not_includes response.body, "Esperienze, categorie e brand"
      assert_not_includes response.body, "Teacher"
      assert_not_includes response.body, "Tutor"
      assert_not_includes response.body, "Professionista"
    end

    private

      def create_user(email)
        User.create!(
          email_address: email,
          password: "password123",
          password_confirmation: "password123"
        ).tap do |user|
          user.create_profile!(display_name: email.split("@").first)
        end
      end

      def sign_in(user)
        post session_url, params: { email_address: user.email_address, password: "password123" }
      end
  end
end
