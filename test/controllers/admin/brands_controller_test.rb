require "test_helper"

class Admin::BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superadmin = User.create!(
      email_address: "brands-superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    profile = @superadmin.create_profile!(display_name: "Brands Admin")
    role = RoleAssignment.create!(profile: profile, role: "creator_of_worlds")

    @brand = Node.create!(role_assignment: role, title: "PosturaCorretta", node_type: "brand", status: "published")
    @project = Node.create!(role_assignment: role, parent: @brand, title: "Canale YouTube", node_type: "project", status: "draft")
    @bridge = Node.create!(role_assignment: role, title: "Radioestesia", node_type: "bridge", link_node: @brand, status: "draft")
    Domain.create!(hostname: "brands-example.test", locale: "it", node: @brand, role_assignment: role, active: true)

    post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
  end

  test "superadmin sees alphabetical brands with domains but not internal projects" do
    get admin_brands_url

    assert_response :success
    assert_select "h1", "Brand e progetti"
    assert_select "a[href='#{admin_brands_path}']", text: /Brand/
    assert_select "a", "PosturaCorretta"
    assert_select "a", text: /brands-example\.test/
    assert_select "a", { text: "Canale YouTube", count: 0 }
  end

  test "superadmin sees the node sheet" do
    get admin_brand_url(@brand)

    assert_response :success
    assert_select "h1", "PosturaCorretta"
    assert_select "a", "Albero"
    assert_select "h2", "Struttura"
    assert_select "a", text: /brands-example\.test/
    assert_select "a", "Canale YouTube"
  end

  test "superadmin manages domains from the domains tab" do
    get admin_brands_url(tab: "domains")

    assert_response :success
    assert_select "a[href='#{admin_brands_path(tab: 'domains')}']", text: "Domini"
    assert_select "a", "brands-example.test"
    assert_select "a", "Nuovo dominio"
  end
end
