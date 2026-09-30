require "test_helper"

class Brands::Admin::NodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superadmin = User.create!(email_address: "brand-nodes-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
    profile = @superadmin.create_profile!(display_name: "Brand Nodes Admin")
    role = RoleAssignment.create!(profile: profile, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: role, title: "PosturaCorretta", slug: "posturacorretta", status: "published")
    Domain.create!(hostname: "brand-nodes.test", node: @brand, role_assignment: role, active: true)
    @project = Node.create!(parent: @brand, title: "Primo progetto", status: "draft")
  end

  test "brand node map is private" do
    get brand_admin_nodes_url(@brand.slug)

    assert_redirected_to new_session_url(return_to: brand_admin_nodes_path(@brand.slug))
  end

  test "superadmin sees the real node tree and the add controls" do
    sign_in_superadmin

    get brand_admin_nodes_url(@brand.slug)

    assert_response :success
    assert_select "h1", "PosturaCorretta · Nodi"
    assert_select "button[data-node-dialog-open]", text: "+ Nodo"
    assert_select "[role='tree'] a[href='#{brand_admin_node_path(@brand.slug, @project)}']", text: "Primo progetto"
    assert_select "button[data-node-add-parent='#{@project.id}']", text: "+ sotto"
    assert_select "#brand-node-map-data", count: 0
  end

  test "superadmin opens the visual schema in a separate tab" do
    sign_in_superadmin

    get brand_admin_nodes_url(@brand.slug, view: "schema")

    assert_response :success
    assert_select "a[aria-current='page']", text: "Schema"
    assert_select "#brand-node-map-svg"
    assert_select "#brand-node-map-data", text: /Primo progetto/
    assert_select "#brand-node-map-data", text: /Iscrizione al percorso online/, count: 0
  end

  test "superadmin creates a real child node from the brand map" do
    sign_in_superadmin

    assert_difference -> { Node.count }, 1 do
      post brand_admin_nodes_url(@brand.slug), params: { node: { title: "Corso online", parent_id: @project.id, description: "Primo passo reale", status: "draft" } }
    end

    node = Node.order(:created_at).last
    assert_equal @project, node.parent
    assert_equal @brand.role_assignment, node.role_assignment
    assert_redirected_to brand_admin_node_url(@brand.slug, node)
  end

  test "opening a node shows its processes" do
    process_record = BrandProcess.create!(node: @project, created_by_user: @superadmin, title: "Pubblicazione settimanale", status: "active")
    sign_in_superadmin

    get brand_admin_node_url(@brand.slug, @project)

    assert_response :success
    assert_select "h1", "Primo progetto"
    assert_select "h2", "Processi"
    assert_select "h3", process_record.title
    assert_select "a[href='#{admin_brand_path(@project, tab: "processes")}']", text: /Gestisci processi/
    assert_select "form[action='#{brand_admin_node_path(@brand.slug, @project)}'] select[name='node[link_node_id]']"
    assert_select "a[href='#{brand_admin_node_path(@brand.slug, @project)}'][data-turbo-method='delete']", text: "Elimina nodo"
  end

  test "superadmin creates a bridge node" do
    target = Node.create!(role_assignment: @brand.role_assignment, title: "Progetto collegato", slug: "progetto-collegato")
    sign_in_superadmin

    assert_difference -> { Node.count }, 1 do
      post brand_admin_nodes_url(@brand.slug), params: { node: { title: "Ponte al progetto", parent_id: @brand.id, link_node_id: target.id, status: "draft" } }
    end

    bridge = Node.order(:created_at).last
    assert_equal target, bridge.link_node
    assert bridge.bridge_node?
  end

  test "superadmin updates and deletes a leaf node" do
    sign_in_superadmin

    patch brand_admin_node_url(@brand.slug, @project), params: { node: { title: "Progetto aggiornato", parent_id: @brand.id, status: "published" } }

    assert_redirected_to brand_admin_node_url(@brand.slug, @project)
    @project.reload
    assert_equal ["Progetto aggiornato", "published"], [@project.title, @project.status]

    assert_difference -> { Node.count }, -1 do
      delete brand_admin_node_url(@brand.slug, @project)
    end
    assert_redirected_to brand_admin_nodes_url(@brand.slug)
  end

  test "superadmin cannot delete a node that still has children" do
    Node.create!(parent: @project, title: "Figlio")
    sign_in_superadmin

    assert_no_difference -> { Node.count } do
      delete brand_admin_node_url(@brand.slug, @project)
    end

    assert_redirected_to brand_admin_node_url(@brand.slug, @project)
    assert_equal "Prima di eliminare il nodo, ricolloca o elimina i nodi figli.", flash[:alert]
  end

  private

    def sign_in_superadmin
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
    end
end
