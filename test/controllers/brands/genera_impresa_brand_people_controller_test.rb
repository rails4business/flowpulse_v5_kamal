require "test_helper"

class Brands::GeneraImpresaBrandPeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "brand-people-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa",
      role_assignment: @root_assignment,
      operator_roles: %w[gestore_generaimpresa imprenditore_generaimpresa]
    )
    @domain = Domain.create!(hostname: "brand-people.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @manager = User.create!(email_address: "brand-people-manager@example.com", password: "password123")
    manager_profile = @manager.create_profile!(display_name: "Manager")
    manager_access = BrandAccess.create!(profile: manager_profile, source_domain: @domain)
    manager_access.create_brand_credential!(
      brand_node: @brand,
      email_address: @manager.email_address,
      password: "password123"
    )
    manager_assignment = RoleAssignment.create!(
      profile: manager_profile,
      role: :operator,
      role_operator: "gestore_generaimpresa",
      context: @brand,
      parent: @root_assignment,
      brand_access: manager_access
    )
    manager_access.select_role_assignment!(manager_assignment)
    @person = User.create!(email_address: "brand-person@example.com", password: "password123")
    @person_profile = @person.create_profile!(display_name: "Brand Person")
    @person_access = BrandAccess.create!(profile: @person_profile, source_domain: @domain)
    host! @domain.hostname
  end

  test "manager sees only GeneraImpresa profiles and accesses" do
    other_owner = User.create!(email_address: "other-brand-owner@example.com", password: "password123")
    other_owner.create_profile!(display_name: "Other owner")
    other_assignment = RoleAssignment.create!(profile: other_owner.profile, role: :ideatore)
    other_brand = Node.create!(title: "Other brand", slug: "other-brand-people", role_assignment: other_assignment)
    other_domain = Domain.create!(hostname: "other-brand-people.example", node: other_brand, role_assignment: other_assignment, locale: "it")
    outsider = User.create!(email_address: "outsider-brand@example.com", password: "password123")
    outsider_profile = outsider.create_profile!(display_name: "Outsider")
    BrandAccess.create!(profile: outsider_profile, source_domain: other_domain)
    sign_in(@manager)

    get genera_impresa_people_url

    assert_response :success
    assert_select "aside", text: /Access role.*Gestore GeneraImpresa/m
    assert_select "[data-brand-access-id='#{@person_access.id}']", text: /Brand Person/
    assert_select "body", text: /Outsider/, count: 0
    assert_select "a[href='#{admin_profile_path(@person_profile)}']", count: 0
  end

  test "manager dashboard shows only GeneraImpresa functions allowed by the role" do
    sign_in(@manager)

    get brand_admin_root_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-nav a", count: 1, text: "Dashboard"
    assert_select "main a", text: /Richieste/
    assert_select "main a", text: /Persone/
    assert_select "main a", text: /Progetti/
    assert_select "main a", text: /Nodi/, count: 0
    assert_select "main a", text: /Privacy/, count: 0
  end

  test "manager revokes a GeneraImpresa access" do
    sign_in(@manager)

    delete genera_impresa_person_url(@person_access)

    assert_redirected_to genera_impresa_people_path
    assert_equal "cancelled", @person_access.reload.status
  end

  test "manager generates a manual verification email for a pending Brand credential" do
    credential = @person_access.create_brand_credential!(
      brand_node: @brand,
      email_address: @person.email_address,
      password: "password123",
      status: "pending_verification"
    )
    sign_in(@manager)

    assert_no_enqueued_emails do
      assert_difference -> { EmailVerification.count }, 1 do
        post resend_genera_impresa_person_verification_url(@person_access)
      end
    end

    assert_redirected_to genera_impresa_people_path
    assert_equal credential, @person_access.reload.brand_credential
    assert_equal "pending_verification", credential.reload.status
    follow_redirect!
    assert_select "input[value^='https://#{@domain.hostname}/email-verification/']", count: 1
    assert_select "a[href^='mailto:#{@person.email_address}']", text: "Apri email"
  end

  test "entrepreneur cannot open the Brand people index" do
    entrepreneur = User.create!(email_address: "brand-people-entrepreneur@example.com", password: "password123")
    profile = entrepreneur.create_profile!(display_name: "Entrepreneur")
    access = BrandAccess.create!(profile:, source_domain: @domain)
    access.create_brand_credential!(
      brand_node: @brand,
      email_address: entrepreneur.email_address,
      password: "password123"
    )
    assignment = RoleAssignment.create!(
      profile:,
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: @brand,
      parent: @root_assignment,
      brand_access: access
    )
    access.select_role_assignment!(assignment)
    sign_in(entrepreneur)

    get genera_impresa_people_url

    assert_response :forbidden
  end

  test "superadmin sees the link to the global profile" do
    superadmin = User.create!(email_address: "brand-people-superadmin@example.com", password: "password123", superadmin: true)
    superadmin.create_profile!(display_name: "Superadmin")
    sign_in(superadmin)

    get genera_impresa_people_url

    assert_response :success
    assert_select "aside", text: /Access role.*Superadmin/m
    assert_select "a[href='https://flowpulse.net#{admin_profile_path(@person_profile)}']", text: "Scheda globale"
  end

  test "canonical Brand dashboard uses the same policy as direct section access" do
    sign_in(@manager)
    get "/admin"

    assert_response :success
    assert_select "body[data-layout='dashboard'].brand-admin-body"
    assert_select "aside nav a[href='/admin'][aria-current='page']", text: /Dashboard/
    assert_select "[data-dashboard-section]", count: 3
    assert_select "[data-dashboard-section='requests'][href='/admin/requests']"
    assert_select "[data-dashboard-section='brand_people'][href='/admin/people']"
    assert_select "[data-dashboard-section='projects'][href='/admin/projects']"

    get "/admin/requests"
    assert_response :success
    assert_select "aside nav a[href='/admin'][aria-current='page']", text: /Dashboard/
    assert_select "nav[aria-label='Breadcrumb'] a[href='/admin']"
    get "/admin/nodes"
    assert_response :forbidden
    get brand_admin_privacy_path(@brand.slug)
    assert_response :forbidden
  end

  test "localhost keeps the Brand prefix for dashboard sections and breadcrumbs" do
    host! "localhost"
    post session_path, params: { site: @brand.slug, email_address: @manager.email_address, password: "password123" }
    get "/generaimpresa/admin"

    assert_response :success
    assert_select "[data-dashboard-section='requests'][href='/generaimpresa/admin/requests']"
    assert_select "[data-dashboard-section='brand_people'][href='/generaimpresa/admin/people']"
    get "/generaimpresa/admin/requests"
    assert_response :success
    assert_select "nav[aria-label='Breadcrumb'] a[href='/generaimpresa/admin']"
  end

  test "entrepreneur dashboard links to project people instead of the whole Brand people index" do
    assignment = @manager.profile.role_assignments.operator.first
    assignment.update!(role_operator: "imprenditore_generaimpresa")
    project = Node.create!(title: "Entrepreneur project", parent: @brand, role_assignment: @root_assignment,
      responsible_profile: @manager.profile)
    sign_in(@manager)

    get "/admin"

    assert_response :success
    assert_select "[data-dashboard-section]", count: 1
    assert_select "[data-dashboard-section='projects'][href='/admin/projects']"
    assert_select "aside nav", text: /Persone GeneraImpresa/, count: 0
    get "/admin/people"
    assert_response :forbidden
    get "/admin/projects"
    assert_response :success
    assert_select "[data-managed-node-id='#{project.id}'] a", text: "Persone del progetto"
    get genera_impresa_project_people_path(project)
    assert_response :success
    assert_select "a", text: "Apri le richieste del Brand", count: 0
  end

  test "ordinary Brand access exposes no administrative navigation or dashboard" do
    @person_access.create_brand_credential!(brand_node: @brand, email_address: @person.email_address, password: "password123")
    sign_in(@person)

    get profile_path

    assert_response :success
    assert_select "aside nav a[href*='/admin']", count: 0
    get "/admin"
    assert_response :forbidden
    get "/admin/projects"
    assert_response :forbidden
  end

  test "a manager can read projects covered by the role even when another person is responsible" do
    project = Node.create!(title: "Other responsible person", parent: @brand,
      role_assignment: @root_assignment, responsible_profile: @person_profile)
    sign_in(@manager)

    get "/admin/projects"

    assert_response :success
    assert_select "[data-managed-node-id='#{project.id}']"
    assert_select "nav[aria-label='Breadcrumb'] a[href='/admin']"
  end

  test "multiple roles require a selection and changing it updates the dashboard sections" do
    access = @manager.profile.brand_accesses.find_by!(brand_node: @brand)
    manager_role = access.current_role_assignment
    entrepreneur = RoleAssignment.create!(profile: @manager.profile, role: :operator,
      role_operator: "imprenditore_generaimpresa", context: @brand, parent: @root_assignment, brand_access: access)
    access.select_role_assignment!(nil)
    sign_in(@manager)
    get "/admin"

    assert_response :success
    assert_select "h2", "Scegli con quale ruolo operare"
    assert_select "[data-dashboard-section]", count: 0
    patch dashboard_brand_access_current_role_path(access), params: { role_assignment_id: entrepreneur.id }
    get "/admin"
    assert_select "[data-dashboard-section]", count: 1

    patch dashboard_brand_access_current_role_path(access), params: { role_assignment_id: manager_role.id }
    get "/admin"
    assert_select "[data-dashboard-section]", count: 3
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
