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
      assert_not_includes response.body, "I tuoi nuovi domini"
      assert_not_includes response.body, "Dashboard Canale"
      assert_not_includes response.body, "Alberi Nodi"
    end

    test "creator dashboard shows assigned domains without root node" do
      user = create_user("creator-dashboard-domain-without-node@example.com")
      assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
      Domain.create!(hostname: "posturacorretta.test", role_assignment: assignment, locale: "it")
      Domain.create!(hostname: "www.posturacorretta.test", canonical_host: "posturacorretta.test", role_assignment: assignment, locale: "it")
      user.update!(active_role: :creator, current_role_assignment: assignment)

      sign_in(user)
      get creator_world_root_url

      assert_response :success
      assert_includes response.body, "I tuoi nuovi domini"
      assert_includes response.body, "1 da configurare"
      assert_includes response.body, "posturacorretta.test"
      assert_includes response.body, "www.posturacorretta.test"
      assert_includes response.body, "Da collegare"
      assert_includes response.body, "Nessun nodo iniziale associato"
      assert_includes response.body, "Crea root node"
      assert_includes response.body, "Alias:"
    end

    test "creator dashboard filters associated roots by current domain and keeps free roots" do
      user = create_user("creator-dashboard-domain-filter@example.com")
      assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
      current_root = Node.create!(title: "Postura Root", role_assignment: assignment)
      free_root = Node.create!(title: "Free Root", role_assignment: assignment)
      other_root = Node.create!(title: "Other Domain Root", role_assignment: assignment)
      Domain.create!(hostname: "posturacorretta.test", node: current_root, locale: "it")
      Domain.create!(hostname: "www.posturacorretta.test", canonical_host: "posturacorretta.test", role_assignment: assignment, locale: "it")
      Domain.create!(hostname: "other-domain.test", node: other_root, locale: "it")
      user.update!(active_role: :creator, current_role_assignment: assignment)

      host! "posturacorretta.test"
      sign_in(user)
      get creator_world_root_url

      assert_response :success
      assert_includes response.body, "Vista dominio: posturacorretta.test"
      assert_includes response.body, "Postura Root"
      assert_includes response.body, "Free Root"
      assert_not_includes response.body, "Other Domain Root"
    end

    test "creator dashboard only shows new domains for current domain context" do
      user = create_user("creator-dashboard-new-domain-filter@example.com")
      assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
      Domain.create!(hostname: "posturacorretta.test", role_assignment: assignment, locale: "it")
      Domain.create!(hostname: "other-domain.test", role_assignment: assignment, locale: "it")
      user.update!(active_role: :creator, current_role_assignment: assignment)

      host! "posturacorretta.test"
      sign_in(user)
      get creator_world_root_url

      assert_response :success
      assert_includes response.body, "I tuoi nuovi domini"
      assert_includes response.body, "posturacorretta.test"
      assert_not_includes response.body, "other-domain.test"
    end

    test "creator dashboard hides flowpulse base domain from channel domains" do
      user = create_user("creator-dashboard-flowpulse-hidden@example.com")
      assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
      Domain.create!(hostname: "flowpulse.net", role_assignment: assignment, locale: "it", target_controller: "landing", target_action: "flowpulse")
      Domain.create!(hostname: "www.flowpulse.net", canonical_host: "flowpulse.net", role_assignment: assignment, locale: "it")
      user.update!(active_role: :creator, current_role_assignment: assignment)

      sign_in(user)
      get creator_world_root_url

      assert_response :success
      assert_not_includes response.body, "I tuoi nuovi domini"
      assert_not_includes response.body, "Nessun nuovo dominio da configurare"
      assert_not_includes response.body, "flowpulse.net"
      assert_not_includes response.body, "www.flowpulse.net"
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
