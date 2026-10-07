require "test_helper"

class GeneraImpresaControllerTest < ActionDispatch::IntegrationTest
  test "renders the public brand and project catalog" do
    get genera_impresa_url
    assert_response :success
    assert_select "h1", /Dalle idee ai progetti/
    assert_includes response.body, "PosturaCorretta"
    assert_includes response.body, "Flowpulse"
  end

  test "renders a brand with many projects" do
    get genera_impresa_brand_url("posturacorretta")
    assert_response :success
    assert_select "h1", "PosturaCorretta"
    assert_select "h2", "Progetti del brand"
  end

  test "renders a brand with one project" do
    get genera_impresa_brand_url("flowpulse")
    assert_response :success
    assert_select "h1", "Flowpulse"
    assert_select "article", count: 1
  end

  test "renders SvuotaMente as a brand with its webapp project" do
    get genera_impresa_brand_url("svuotamente")
    assert_response :success
    assert_select "h1", "SvuotaMente"
    assert_includes response.body, "Webapp SvuotaMente"

    get genera_impresa_project_url("webapp-svuotamente")
    assert_response :success
    assert_select "a[href=?]", svuotamente_path, text: /Apri la webapp/
  end

  test "renders a public project page" do
    get genera_impresa_project_url("piattaforma-flowpulse-rails4business")
    assert_response :success
    assert_includes response.body, "Step del progetto"
  end

  test "owner sees managed brands domains and FlowPulse administration links" do
    owner = User.create!(email_address: "genera-owner@example.com", password: "password123", password_confirmation: "password123")
    profile = owner.create_profile!(display_name: "Genera Owner", username: "genera_owner")
    assignment = RoleAssignment.create!(profile: profile, role: :creator_of_worlds)
    brand = Node.create!(title: "Brand del proprietario", slug: "brand-del-proprietario", role_assignment: assignment, status: "published")
    Domain.create!(hostname: "brand-proprietario.test", node: brand, role_assignment: assignment, primary: true, active: true)
    post session_url, params: { email_address: owner.email_address, password: "password123" }

    get genera_impresa_url

    assert_response :success
    assert_select "#i-miei-brand h2", "I tuoi Brand e domini"
    assert_select "#i-miei-brand h3", "Brand del proprietario"
    assert_select "a[href='https://brand-proprietario.test']", text: /brand-proprietario\.test/
    assert_select "a[href='#{brand_admin_nodes_path(brand.slug)}']", text: "Nodi"
    assert_select "a[href='#{brand_admin_data_commitments_path(brand.slug)}']", text: "Richieste"
    assert_select "a[href='#{brand_admin_privacy_path(brand.slug)}']", text: "Privacy"
  end

  test "public catalog does not expose the private control room" do
    get genera_impresa_url

    assert_select "#i-miei-brand", count: 0
    assert_select "a", text: "I miei Brand", count: 0
  end
end
