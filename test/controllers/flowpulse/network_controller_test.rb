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

  test "global network starts with the brand directory instead of the graph" do
    get flowpulse_global_network_url(vista: "brand")

    assert_response :success
    assert_select "h1", "Brand"
    assert_select "tbody th[scope='rowgroup']", text: /Brand della rete/
    assert_select "[data-controller='node-network']", count: 0
    assert_select "a[href='#{flowpulse_global_network_path(vista: "brand", node: @project.slug)}']", text: /Progetto del proprietario/
    assert_select "td li", text: "network-project.test"
    assert_select "th[scope='row'] a", text: "Brand Personale", count: 0
  end

  test "lane network starts from a domain and exposes progressive columns" do
    child = Node.create!(
      role_assignment: @owner_role,
      parent: @project,
      title: "Corso nella corsia",
      slug: "network-lane-course",
      node_type: :project,
      status: "published"
    )

    get flowpulse_network_lanes_url(@project.slug, vista: "brand")

    assert_response :success
    assert_select "[data-controller='node-lanes'][data-node-lanes-selected-value='#{@project.slug}']", count: 1
    assert_select "[data-controller='node-lanes'][data-node-lanes-open-value='']", count: 1
    assert_select "svg[data-node-lanes-target='connections']", count: 1
    assert_select "select[data-node-lanes-target='domainSelect'] option[value='#{@project.slug}'][selected]", count: 1
    assert_includes response.body, child.title
    assert_not_includes response.body, @professional.title
    assert_select "a[href='#{flowpulse_automatic_network_node_path("all", @project.slug, vista: "brand")}']", text: "Centralità"
  end

  test "lane network canonicalizes its root and preserves open containers" do
    get flowpulse_network_lanes_root_url(vista: "brand")

    assert_response :redirect
    assert_match %r{/flowpulse/rete/globale/corsie/[^?]+\?vista=brand}, response.location

    get flowpulse_network_lanes_url(@project.slug, vista: "brand", corsie: @project.slug)

    assert_response :success
    assert_select "[data-controller='node-lanes'][data-node-lanes-open-value='#{@project.slug}']", count: 1
    assert_includes response.body, "parent_id"
  end

  test "professional lanes do not mix project nodes" do
    get flowpulse_network_lanes_url(@professional.slug, vista: "professional")

    assert_response :success
    assert_includes response.body, @professional.title
    assert_not_includes response.body, @project.title
    assert_select "a[href='#{flowpulse_automatic_network_node_path("all", @professional.slug, vista: "professional")}']", text: "Centralità"
  end

  test "professional directory lists professional brands and opens their focused graph" do
    sign_in(@owner)

    get flowpulse_global_network_url(vista: "professional")

    assert_response :success
    assert_select "h1", "Professional Brand"
    assert_select "tbody th[scope='rowgroup']", text: /Professional Brand/
    assert_select "a[href='#{flowpulse_global_network_path(vista: "professional", node: @professional.slug)}']", text: /Brand Personale/
    assert_select "th[scope='row'] a", text: "Progetto del proprietario", count: 0

    get flowpulse_global_network_url(vista: "professional", node: @professional.slug)

    assert_response :success
    assert_select "[data-controller='node-network'][data-node-network-selected-value='node-#{@professional.id}']", count: 1
    assert_select "a[href='#{flowpulse_global_network_path(vista: "professional")}']", text: /Elenco/
    assert_select "button", text: "TUTTO", count: 0
  end

  test "automatic network renders a single automatically centered radial map" do
    get flowpulse_automatic_network_url(vista: "brand")

    assert_response :success
    assert_select "[data-controller='node-network'][data-node-network-automatic-center-value='true']", count: 1
    assert_select "[data-controller='node-network'][data-node-network-depth-value='2']", count: 1
    assert_select "a[title='Passa alla vista All']", text: /Vista.*ONLY NODE/m, count: 1
  end

  test "centrality URL configures network presentation and visible levels" do
    get flowpulse_automatic_network_node_url(
      "all",
      @project.slug,
      vista: "brand",
      livelli: "4"
    )

    assert_response :success
    assert_select "[data-controller='node-network'][data-node-network-automatic-center-value='false'][data-node-network-depth-value='4']", count: 1
    assert_select "input[data-node-network-target='depthRange'][value='4']", count: 1
    assert_select "a[title='Passa alla vista Only node'][href*='/centralita/only/#{@project.slug}'][href*='livelli=4']", count: 1

    get flowpulse_automatic_network_node_url(
      "only",
      @project.slug,
      vista: "brand",
      livelli: "tutti"
    )

    assert_response :success
    assert_select "[data-controller='node-network'][data-node-network-automatic-center-value='true'][data-node-network-depth-value='tutti']", count: 1
    assert_select "input[data-node-network-target='depthRange'][value='6']", count: 1
    assert_select "a[title='Passa alla vista All'][href*='/centralita/all/#{@project.slug}'][href*='livelli=tutti']", count: 1
  end

  test "legacy centrality URL redirects to mode and node path" do
    get flowpulse_automatic_network_url(vista: "brand", node: @project.slug, modalita: "only", livelli: "2")

    assert_redirected_to flowpulse_automatic_network_node_url("only", @project.slug, vista: "brand", livelli: "2")
    assert_response :moved_permanently
  end

  test "only node view preserves the requested center" do
    technical_bridge = Node.create!(
      role_assignment: @owner_role,
      parent: @professional,
      professional_owner_node: @professional,
      link_node: @project,
      title: "Accesso tecnico nascosto",
      view_type: "access_bridge",
      status: "published"
    )
    legacy_preview = Node.create!(
      role_assignment: @owner_role,
      parent: @professional,
      professional_owner_node: @professional,
      link_node: @project,
      title: "Vecchia presentazione visibile",
      view_type: "methodology_preview",
      status: "published"
    )

    get flowpulse_automatic_network_node_url("only", @project.slug, vista: "brand")

    assert_response :success
    assert_select "[data-node-network-selected-value='node-#{@project.id}'][data-node-network-fixed-center-value='true']", count: 1
    assert_not_includes response.body, "node-#{technical_bridge.id}"
    assert_not_includes response.body, "professional-owner-#{@professional.id}-#{technical_bridge.id}"
    assert_not_includes response.body, "node-#{legacy_preview.id}"
    assert_not_includes response.body, "bridge-#{legacy_preview.id}-#{@project.id}"
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
