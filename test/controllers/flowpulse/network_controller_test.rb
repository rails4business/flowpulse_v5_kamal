require "test_helper"

class Flowpulse::NetworkControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "network-owner@example.com", password: "password123", password_confirmation: "password123")
    @owner_profile = @owner.create_profile!(display_name: "Network Owner", username: "network_owner")
    @owner_role = RoleAssignment.create!(profile: @owner_profile, role: :ideatore)

    @professional = Node.create!(role_assignment: @owner_role, title: "Brand Personale", slug: "network-personal", node_type: :professional, status: "published")
    @project = Node.create!(role_assignment: @owner_role, professional_owner_node: @professional, title: "Progetto del proprietario", slug: "network-owned-project", node_type: :project, status: "published")
    Domain.create!(hostname: "network-personal.test", node: @professional, role_assignment: @owner_role, active: true)
    Domain.create!(hostname: "network-project.test", node: @project, role_assignment: @owner_role, active: true)

    other_user = User.create!(email_address: "network-other@example.com", password: "password123", password_confirmation: "password123")
    other_profile = other_user.create_profile!(display_name: "Other Owner", username: "network_other")
    other_role = RoleAssignment.create!(profile: other_profile, role: :ideatore)
    @other_brand = Node.create!(role_assignment: other_role, title: "Brand non collegato", slug: "network-other-brand", node_type: :project, status: "published", operator_roles: ["insegnante"])
    Domain.create!(hostname: "network-other.test", node: @other_brand, role_assignment: other_role, active: true)
  end

  test "requires authentication" do
    get flowpulse_network_url

    assert_redirected_to new_session_url(return_to: flowpulse_network_path)
  end

  test "owner sees personal and owned brands but not unrelated brands" do
    sign_in(@owner)

    get flowpulse_network_url

    assert_response :success
    assert_select "h1", "La mia rete"
    assert_select "#professional-brands-title", "Brand professionali e Brand progetto"
    assert_select "ul[aria-label='Albero dei Brand personali']", text: /Brand Personale.*Progetto del proprietario/m
    assert_select "strong", "Brand Personale"
    assert_select "strong", "Progetto del proprietario"
    assert_select "strong", text: "Brand non collegato", count: 0
  end

  test "contextual roles separate administration from collaboration" do
    admin_user = User.create!(email_address: "network-admin@example.com", password: "password123", password_confirmation: "password123")
    admin_profile = admin_user.create_profile!(display_name: "Network Admin", username: "network_admin")
    RoleAssignment.create!(profile: admin_profile, role: :admin, parent: @owner_role, context: @project)
    RoleAssignment.create!(profile: admin_profile, role: :operator, role_operator: "insegnante", parent: @other_brand.role_assignment, context: @other_brand)
    sign_in(admin_user)

    get flowpulse_network_url

    assert_response :success
    assert_select "#administered-brands-title", "Brand amministrati"
    assert_select "#collaborations-title", "Collaborazioni"
    assert_select "section[aria-labelledby='administered-brands-title'] li", text: /Progetto del proprietario.*Amministratore/m
    assert_select "section[aria-labelledby='collaborations-title'] li", text: /Brand non collegato.*Insegnante/m
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
