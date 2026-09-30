require "test_helper"

class Brands::Admin::DevelopmentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "brand-development-owner@example.com", password: "password123", password_confirmation: "password123")
    profile = @owner.create_profile!(display_name: "Brand Development Owner")
    role = RoleAssignment.create!(profile: profile, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: role, title: "PosturaCorretta", slug: "posturacorretta", status: "published")
    Domain.create!(hostname: "brand-development.test", node: @brand, role_assignment: role, active: true)
    post session_url, params: { email_address: @owner.email_address, password: "password123" }
  end

  test "development sheets are presented inside their brand" do
    get brand_admin_development_url(@brand.slug)

    assert_response :success
    assert_select "h1", "PosturaCorretta · Sviluppo"
    assert_select "a[href='#{brand_admin_development_entry_path(@brand.slug, "posturacorretta-programma-lezioni-studente-insegnante")}']"
    assert_select "a", text: /Rails4Business/, count: 0
    assert_select "body.brand-admin-body"
  end

  test "brand cannot open another brand development sheet" do
    get brand_admin_development_entry_url(@brand.slug, "registro-sviluppo-centralizzato")

    assert_response :not_found
  end

  test "brand opens its Markdown development sheet" do
    get brand_admin_development_entry_url(@brand.slug, "posturacorretta-programma-lezioni-studente-insegnante")

    assert_response :success
    assert_select "h1", "Attivare prima il percorso online PosturaCorretta"
    assert_select ".editorial-rich-text h2", "Cose da fare adesso — percorso online"
    assert_select "a[href='#{brand_admin_node_path(@brand.slug, @brand)}']", text: "Node · posturacorretta"
    assert_select "p", text: /config\/data\/brands\/posturacorretta\/development/
  end
end
