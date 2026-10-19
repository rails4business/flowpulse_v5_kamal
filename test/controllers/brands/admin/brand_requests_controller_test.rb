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
    assert_select ".brand-admin-nav a[aria-current='page']", text: "Richieste"
    assert_select "h1", "Corpo e Coscienza · Richieste"
    assert_select "#brand-request-#{@brand_request.id}", text: /Mario Rossi.*mario@example.com.*Milano/m
    assert_select "a[href='mailto:mario@example.com']"
    assert_select "a[href='tel:030123456']"
    assert_select ".brand-admin-filter[aria-current='page']", text: /Aperte · 1/
    assert_select ".brand-admin-badge--request", text: "Ricerca professionista"
    assert_select ".brand-admin-badge--user", text: "Utente"
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

  test "closed requests use outcome filters and all requests use a compact table" do
    @brand_request.update!(status: "accepted", resolved_at: Time.current)
    BrandRequest.create!(
      domain: @domain, brand_node: @brand, subject: @brand, participant_contact: @contact,
      title: "Richiesta da archiviare", kind: "information", audience: "user",
      status: "closed", resolved_at: Time.current
    )
    sign_in(@owner)

    get brand_admin_requests_url(@brand.slug, state: "closed")

    assert_response :success
    assert_select ".brand-admin-filter[aria-current='page']", text: /Chiuse · 2/
    assert_select ".brand-admin-filter--secondary", text: /Accettata · 1/
    assert_select ".brand-admin-filter--secondary", text: /Archiviata · 1/
    assert_select ".brand-admin-filter--secondary", text: /In attesa/, count: 0
    assert_select "table.brand-admin-table", count: 0

    get brand_admin_requests_url(@brand.slug, state: "all")

    assert_response :success
    assert_select "table.brand-admin-table", count: 1
    assert_select "table.brand-admin-table tbody tr", count: 2
    assert_select "table.brand-admin-table a", text: "Apri", count: 2
    assert_select "article[id^='brand-request-']", count: 0
  end

  test "an incompatible status is ignored when filtering open requests" do
    sign_in(@owner)

    get brand_admin_requests_url(@brand.slug, state: "open", status: "accepted")

    assert_response :success
    assert_select "#brand-request-#{@brand_request.id}"
    assert_select ".brand-admin-filter--secondary[aria-current='page']", text: "Tutte le aperte"
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

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
