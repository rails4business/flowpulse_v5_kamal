require "test_helper"

class Brands::Admin::BrandRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "brand-requests-owner@example.com", password: "password123", password_confirmation: "password123")
    @profile = @owner.create_profile!(display_name: "Responsabile Corpo e Coscienza", username: "responsabile_brand_requests")
    assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: assignment, title: "Corpo e Coscienza", slug: "corpoecoscienza", status: "published")
    @domain = Domain.create!(hostname: "corpoecoscienza.test", node: @brand, role_assignment: assignment, active: true)
    @contact = @profile.impegno_contacts.create!(name: "Mario Rossi", email: "mario@example.com", phone: "030123456")
    @brand_request = BrandRequest.create!(
      domain: @domain, brand_node: @brand, subject: @brand, participant_contact: @contact,
      title: "Richiesta professionista", message: "Cerco un professionista nella mia zona.",
      kind: "find_professional", audience: "user", metadata: { "city" => "Milano", "country_code" => "IT" }
    )
  end

  test "brand owner sees requests and contact details" do
    sign_in(@owner)
    get brand_admin_requests_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-nav a", count: 1, text: "Dashboard"
    assert_select "h1", "Corpo e Coscienza · Richieste"
    assert_select "#brand-request-#{@brand_request.id}", text: /Mario Rossi.*mario@example.com.*Milano/m
    assert_select "a[href='mailto:mario@example.com']"
    assert_select "a[href='tel:030123456']"
    assert_select ".brand-admin-filter[aria-current='page']", text: /Aperte · 1/
    assert_select ".brand-admin-badge--request", text: "Ricerca professionista"
    assert_select ".brand-admin-badge--user", text: "Utente"
    assert_select "#brand-request-#{@brand_request.id}", text: /Senza account/
  end

  test "Brand dashboard moves legacy navigation links into the main page" do
    sign_in(@owner)

    get brand_admin_root_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-nav a", count: 1, text: "Dashboard"
    assert_select "main a", text: /Nodi/
    assert_select "main a", text: /Schema/
    assert_select "main a", text: /Sviluppo/
    assert_select "main a", text: /Richieste/
    assert_select "main a", text: /Contenuti/
    assert_select "main a", text: /Impegni/
    assert_select "main a", text: /Privacy/
  end

  test "localhost resolves the current domain from the Brand slug in the route" do
    access = BrandAccess.create!(profile: @profile, source_domain: @domain)
    access.create_brand_credential!(brand_node: @brand, email_address: @owner.email_address, password: "password123")
    host! "localhost"
    post session_url, params: { site: @brand.slug, email_address: @owner.email_address, password: "password123" }

    get brand_admin_requests_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-site-link[href='/corpo-e-coscienza']", text: "Torna al sito"
  end

  test "requests linked to a profile show it next to the contact" do
    person = User.create!(email_address: "mario@example.com", password: "password123")
    @brand_request.update!(requester_profile: person.create_profile!(display_name: "Mario Rossi", username: "mario_rossi"))
    sign_in(@owner)
    get brand_admin_requests_url(@brand.slug)

    assert_select "#brand-request-#{@brand_request.id} [data-requester-profile]", text: /Profilo: Mario Rossi \(@mario_rossi\)/
    assert_select "#brand-request-#{@brand_request.id} [data-requester-profile] a", count: 0
  end

  test "superadmin can open the requester profile management page" do
    person = User.create!(email_address: "elisa@example.com", password: "password123")
    requester = person.create_profile!(display_name: "Elisa Corubolo", username: "elisa_corubolo")
    @brand_request.update!(requester_profile: requester)
    superadmin = User.create!(
      email_address: "requests-superadmin@example.com",
      password: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    sign_in(superadmin)

    get brand_admin_requests_url(@brand.slug)

    assert_response :success
    assert_select "#brand-request-#{@brand_request.id} [data-requester-profile] a[href='#{admin_profile_path(requester)}']", text: /Elisa Corubolo/
  end

  test "owner moves a request through waiting and accepted states" do
    sign_in(@owner)

    patch brand_admin_request_state_url(@brand.slug, @brand_request), params: { transition: "wait" }
    assert_equal "waiting", @brand_request.reload.status
    assert_nil @brand_request.resolved_at

    patch brand_admin_request_state_url(@brand.slug, @brand_request), params: { transition: "accept" }
    assert_equal "accepted", @brand_request.reload.status
    assert @brand_request.resolved_at.present?
  end

  test "rejecting a request returns to the open requests list" do
    sign_in(@owner)

    patch brand_admin_request_state_url(@brand.slug, @brand_request), params: { transition: "reject" }

    assert_equal "rejected", @brand_request.reload.status
    assert @brand_request.resolved_at.present?
    assert_redirected_to brand_admin_requests_url(@brand.slug, state: "open")
  end

  test "brand administrator permanently deletes a request without operational history" do
    sign_in(@owner)

    assert_difference -> { BrandRequest.count }, -1 do
      delete brand_admin_request_url(@brand.slug, @brand_request)
    end

    assert_redirected_to brand_admin_requests_url(@brand.slug, state: "all")
    assert_equal "Richiesta eliminata definitivamente.", flash[:notice]
  end

  test "brand administrator cannot delete a request that produced an access grant" do
    person = User.create!(email_address: "request-history@example.com", password: "password123")
    profile = person.create_profile!(display_name: "Request history")
    access = BrandAccess.create!(profile:, source_domain: @domain)
    BrandAccessGrant.create!(
      brand_access: access,
      node: @brand,
      brand_request: @brand_request,
      granted_by_profile: @profile,
      status: "active",
      granted_at: Time.current
    )
    sign_in(@owner)

    assert_no_difference -> { BrandRequest.count } do
      delete brand_admin_request_url(@brand.slug, @brand_request)
    end

    assert_equal "La richiesta ha già prodotto accessi o attività: conservala nello storico.", flash[:alert]
  end

  test "closed requests use outcome filters and table layout is used for all views" do
    @brand_request.update!(status: "accepted", resolved_at: Time.current)
    BrandRequest.create!(
      domain: @domain, brand_node: @brand, subject: @brand, participant_contact: @contact,
      title: "Richiesta da rifiutare", kind: "information", audience: "user",
      status: "rejected", resolved_at: Time.current
    )
    sign_in(@owner)

    get brand_admin_requests_url(@brand.slug, state: "closed")

    assert_response :success
    assert_select ".brand-admin-filter[aria-current='page']", text: /Chiuse · 2/
    assert_select ".brand-admin-filter--secondary", text: /Accettate · 1/
    assert_select ".brand-admin-filter--secondary", text: /Rifiutate · 1/
    assert_select ".brand-admin-filter--secondary", text: /In attesa/, count: 0
    assert_select "table.brand-admin-table", count: 1

    get brand_admin_requests_url(@brand.slug, state: "all")

    assert_response :success
    assert_select "table.brand-admin-table", count: 1
    assert_select "table.brand-admin-table tbody tr", count: 2
    assert_select ".brand-admin-filter--secondary", count: 0
  end

  test "open requests do not display secondary status submenu" do
    sign_in(@owner)

    get brand_admin_requests_url(@brand.slug, state: "open", status: "accepted")

    assert_response :success
    assert_select "#brand-request-#{@brand_request.id}"
    assert_select ".brand-admin-filter--secondary", count: 0
  end

  test "access request creates a linked invitation" do
    @brand_request.update!(kind: "access")
    sign_in(@owner)

    assert_no_emails do
      assert_difference -> { BrandInvitation.count }, 1 do
        post brand_admin_request_invitation_url(@brand.slug, @brand_request)
      end
    end

    invitation = BrandInvitation.order(:created_at).last
    assert_equal @brand_request, invitation.brand_request
    assert_equal @contact.email, invitation.email_address
    assert_equal "invited", @brand_request.reload.status
    follow_redirect!
    assert_select "input#brand-invitation-url[value*='/brand-invitations/']"
  end

  test "owner approves a linked access request and creates the brand access" do
    person = User.create!(email_address: "access-requester@example.com", password: "password123")
    requester = person.create_profile!(display_name: "Access Requester")
    @brand_request.update!(kind: "access", requester_profile: requester)
    sign_in(@owner)

    assert_difference -> { requester.brand_accesses.count }, 1 do
      post brand_admin_request_approve_access_url(@brand.slug, @brand_request)
    end

    assert_equal "accepted", @brand_request.reload.status
    assert_equal @profile, @brand_request.assigned_to_profile
    assert @brand_request.resolved_at.present?
    assert_equal @brand, requester.brand_accesses.active.first.brand_node
    assert_empty requester.role_assignments
  end

  test "entrepreneur cannot administer access requests from the GeneraImpresa root yet" do
    @brand.update!(slug: "generaimpresa", operator_roles: %w[gestore_generaimpresa imprenditore_generaimpresa])
    entrepreneur = User.create!(email_address: "requests-entrepreneur@example.com", password: "password123")
    entrepreneur_profile = entrepreneur.create_profile!(display_name: "Entrepreneur")
    entrepreneur_access = BrandAccess.create!(profile: entrepreneur_profile, source_domain: @domain)
    project = Node.create!(title: "Assigned project", parent: @brand, role_assignment: @brand.role_assignment, responsible_profile: entrepreneur_profile)
    outside = Node.create!(title: "Outside project", parent: @brand, role_assignment: @brand.role_assignment)
    RoleAssignment.create!(
      profile: entrepreneur_profile,
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: project,
      parent: @brand.role_assignment,
      brand_access: entrepreneur_access
    )
    inside_person = User.create!(email_address: "inside-request@example.com", password: "password123")
    inside_profile = inside_person.create_profile!(display_name: "Inside person")
    outside_person = User.create!(email_address: "outside-request@example.com", password: "password123")
    outside_profile = outside_person.create_profile!(display_name: "Outside person")
    inside_request = BrandRequest.create!(domain: @domain, brand_node: @brand, subject: project, requester_profile: inside_profile, title: "Inside", kind: "access", audience: "user")
    outside_request = BrandRequest.create!(domain: @domain, brand_node: @brand, subject: outside, requester_profile: outside_profile, title: "Outside", kind: "access", audience: "user")
    sign_in(entrepreneur)

    get brand_admin_requests_url(@brand.slug)
    assert_response :forbidden

    post brand_admin_request_approve_access_url(@brand.slug, inside_request)
    assert_response :forbidden
    assert_equal "open", inside_request.reload.status
    assert_not inside_profile.brand_accesses.exists?
    assert_equal "open", outside_request.reload.status
    assert_not outside_profile.brand_accesses.exists?
  end

  test "GeneraImpresa manager sees and approves root access requests" do
    @brand.update!(slug: "generaimpresa", operator_roles: %w[gestore_generaimpresa imprenditore_generaimpresa])
    manager = User.create!(email_address: "requests-manager@example.com", password: "password123")
    manager_profile = manager.create_profile!(display_name: "Manager")
    manager_access = BrandAccess.create!(profile: manager_profile, source_domain: @domain)
    manager_assignment = RoleAssignment.create!(
      profile: manager_profile,
      role: :operator,
      role_operator: "gestore_generaimpresa",
      context: @brand,
      parent: @brand.role_assignment,
      brand_access: manager_access
    )
    manager_access.select_role_assignment!(manager_assignment)
    requester_user = User.create!(email_address: "manager-approved@example.com", password: "password123")
    requester = requester_user.create_profile!(display_name: "Manager approved")
    @brand_request.update!(kind: "access", requester_profile: requester)
    host! @domain.hostname
    sign_in(manager)

    get brand_admin_requests_url(@brand.slug)
    assert_response :success
    assert_select "#brand-request-#{@brand_request.id}"

    assert_difference -> { requester.brand_accesses.count }, 1 do
      post brand_admin_request_approve_access_url(@brand.slug, @brand_request)
    end
    assert_equal "accepted", @brand_request.reload.status
    assert_equal manager_profile, @brand_request.assigned_to_profile
  end

  test "a real brand host cannot open another brand administration through the route" do
    other = Node.create!(title: "Another Brand", slug: "another-admin-brand", role_assignment: @brand.role_assignment)
    domain = Domain.create!(hostname: "another-admin-brand.example", node: other, role_assignment: @brand.role_assignment)
    host! domain.hostname
    sign_in(@owner)

    get brand_admin_requests_url(@brand.slug)

    assert_response :not_found
  end

  private

    def sign_in(user)
      domain = Domain.find_by(hostname: URI.parse(session_url).host)
      if domain&.node
        access = BrandAccess.find_by(profile: user.profile, brand_node: domain.node) ||
          BrandAccess.create!(profile: user.profile, source_domain: domain)
        access.create_brand_credential!(
          brand_node: domain.node,
          email_address: user.email_address,
          password: "password123"
        ) unless access.brand_credential
      end
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
