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

    @professional = Node.create!(role_assignment: role, title: "MarkPostura", slug: "admin-markpostura", node_type: :professional, status: "published")
    @brand = Node.create!(role_assignment: role, parent: @professional, professional_owner_node: @professional, title: "PosturaCorretta", node_type: :project, status: "published")
    @project = Node.create!(role_assignment: role, parent: @brand, title: "Canale YouTube", node_type: "project", status: "draft")
    @bridge = Node.create!(role_assignment: role, title: "Radioestesia", node_type: :project, link_node: @brand, status: "draft")
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

  test "superadmin sees nodes collected under brand in costruzione" do
    container = Node.create!(role_assignment: @professional.role_assignment, parent: @professional, title: "Brand in costruzione", slug: "brand-in-costruzione", node_type: :project)
    candidate = Node.create!(role_assignment: @professional.role_assignment, parent: container, title: "Radioestesia e Benessere", slug: "radioestesia", node_type: :professional)

    get admin_brands_url(tab: "building")

    assert_response :success
    assert_select "h1", "Brand in costruzione"
    assert_select "a[href='#{admin_brand_path(candidate)}']", text: "Radioestesia e Benessere"
    assert_select "a[href='/flowpulse/radioestesia'][target='_blank']", text: "Apri anteprima"
  end

  test "superadmin sees the node sheet" do
    get admin_brand_url(@brand)

    assert_response :success
    assert_select "h1", "PosturaCorretta"
    assert_select "a", "Albero"
    assert_select "h2", "Struttura"
    assert_select "a", text: /brands-example\.test/
    assert_select "a", "Canale YouTube"
    assert_select "a[href=?]", admin_brand_path(@brand, tab: "services"), "Servizi"
    assert_select "a[href=?]", admin_brand_path(@brand, tab: "calendars"), "Calendari"
    assert_select "a[href=?]", admin_brand_path(@brand, tab: "processes"), "Processi"
  end

  test "superadmin creates a service on a Project Node" do
    assert_difference -> { Service.count }, 1 do
      post admin_brand_services_url(@project), params: {
        service: { title: "Registrazione video", slug: "registrazione-video", active: true }
      }
    end

    service = Service.order(:created_at).last
    assert_equal @project, service.node
    assert_equal @superadmin, service.created_by_user
    assert_redirected_to admin_brand_url(@project, tab: "services")
  end

  test "superadmin creates a professional calendar linked to a Brand" do
    assert_difference -> { ProfessionalCalendar.count }, 1 do
      post admin_brand_calendars_url(@professional), params: {
        professional_calendar: { context_node_id: @project.id, title: "Gruppo", slug: "admin-postura-gruppo", color: "sky", active: true }
      }
    end

    calendar = ProfessionalCalendar.order(:created_at).last
    assert_equal [@professional, @project], [calendar.professional_node, calendar.context_node]
    assert_redirected_to admin_brand_url(@professional, tab: "calendars")
  end

  test "superadmin creates a Brand process" do
    assert_difference -> { BrandProcess.count }, 1 do
      post admin_brand_processes_url(@brand), params: {
        brand_process: { title: "Produzione video", slug: "produzione-video", status: "active" }
      }
    end

    process_record = BrandProcess.order(:created_at).last
    assert_equal @brand, process_record.node
    assert_equal @superadmin, process_record.created_by_user
    assert_redirected_to admin_brand_url(@brand, tab: "processes")
  end

  test "superadmin sees the editorial material register for a configured brand" do
    get admin_brand_url(@brand, tab: "material")

    assert_response :success
    assert_select "a", "Materiale"
    assert_select "h2", "Materiale di PosturaCorretta"
    assert_includes response.body, "Corsi online"
    assert_select "a[href='#{admin_brand_editorial_material_path(@brand, entry_id: "corsi-e-capitoli")}']", "posturacorretta/contenuti/contents.yml"
  end

  test "superadmin can inspect a registered editorial source" do
    get admin_brand_editorial_material_url(@brand, entry_id: "corsi-e-capitoli")

    assert_response :success
    assert_select "h1", "Corsi online e capitoli"
    assert_includes response.body, "config/data/posturacorretta/contenuti/contents.yml"
  end

  test "superadmin manages domains from the domains tab" do
    get admin_brands_url(tab: "domains")

    assert_response :success
    assert_select "a[href='#{admin_brands_path(tab: 'domains')}']", text: "Domini"
    assert_select "a", "brands-example.test"
    assert_select "a", "Nuovo dominio"
  end
end
