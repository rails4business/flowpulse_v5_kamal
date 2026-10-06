require "test_helper"

class Brands::Admin::DataCommitmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "brand-commitments-owner@example.com", password: "password123", password_confirmation: "password123")
    @profile = @owner.create_profile!(display_name: "Responsabile Corpo e Coscienza", username: "responsabile_brand_commitments")
    assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: assignment, title: "Corpo e Coscienza", slug: "corpoecoscienza", status: "published")
    @domain = Domain.create!(hostname: "corpoecoscienza.test", node: @brand, role_assignment: assignment, active: true)
    @contact = @profile.impegno_contacts.create!(name: "Mario Rossi", email: "mario@example.com", phone: "030123456")
    @brand_request = @profile.data_commitments.create!(
      created_by_profile: @profile, domain: @domain, subject: @brand, participant_contact: @contact,
      title: "Richiesta professionista", description: "Cerco un professionista nella mia zona.",
      kind: "service", status: "requested", starts_at: nil, blocks_calendar: false,
      pricing_type: "none", contribution_type: "unpaid", calendar_key: "brand:#{@brand.id}:requests",
      calendar_label: "Richieste · Corpo e Coscienza",
      metadata: { "request_kind" => "find_professional", "request_audience" => "user", "city" => "Milano", "country_code" => "IT" }
    )
  end

  test "brand admin area requires authentication" do
    get brand_admin_data_commitments_url(@brand.slug)

    assert_redirected_to new_session_url(return_to: brand_admin_data_commitments_path(@brand.slug))
  end

  test "brand owner sees requests and contact details" do
    sign_in(@owner)
    get brand_admin_data_commitments_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-nav a[aria-current='page']", text: "Impegni e richieste"
    assert_select "h1", "Corpo e Coscienza · Impegni e richieste"
    assert_select "#data-commitment-#{@brand_request.id}", text: /Mario Rossi.*mario@example.com.*Milano/m
    assert_select "a[href='mailto:mario@example.com']"
    assert_select "a[href='tel:030123456']"
    assert_select "a[href='#{brand_admin_data_commitments_path(@brand.slug, state: 'open', status: 'requested')}']", text: /Richiesto · 1/
    assert_select ".brand-admin-filter[aria-current='page']", text: /Aperte · 1/
    assert_select ".brand-admin-badge--request", text: "Ricerca professionista"
    assert_select ".brand-admin-badge--user", text: "Utente"
    assert_select "form[action='#{brand_admin_data_commitment_state_path(@brand.slug, @brand_request)}'] button", text: "Prendi in carico"
  end

  test "readable brand slug resolves to the canonical node" do
    sign_in(@owner)
    get brand_admin_data_commitments_url("corpo-e-coscienza")

    assert_response :success
    assert_select "h1", "Corpo e Coscienza · Impegni e richieste"
    assert_select "#data-commitment-#{@brand_request.id}"
    assert_select "a[href='#{brand_admin_data_commitments_path(@brand.slug)}']", text: "Impegni e richieste"
  end

  test "status filter and brand boundary are enforced" do
    other_user = User.create!(email_address: "other-brand@example.com", password: "password123", password_confirmation: "password123")
    other_profile = other_user.create_profile!(display_name: "Altro brand")
    other_assignment = RoleAssignment.create!(profile: other_profile, role: :creator_of_worlds)
    other_brand = Node.create!(role_assignment: other_assignment, title: "Altro", slug: "altro-brand")
    other_domain = Domain.create!(hostname: "altro-brand.test", node: other_brand, role_assignment: other_assignment, active: true)
    other_profile.data_commitments.create!(created_by_profile: other_profile, domain: other_domain, subject: other_brand, title: "Non visibile", kind: "work", status: "completed", starts_at: Time.current, calendar_key: "other", calendar_label: "Altro")

    sign_in(@owner)
    get brand_admin_data_commitments_url(@brand.slug, state: "closed", status: "completed")

    assert_response :success
    assert_select "#data-commitment-#{@brand_request.id}", count: 0
    assert_select "article", text: /Non visibile/, count: 0
    assert_select "p", text: /Non ci sono DataCommitment con stato Completato/
  end

  test "owner closes and reopens a request without scheduling it" do
    sign_in(@owner)

    patch brand_admin_data_commitment_state_url(@brand.slug, @brand_request), params: { transition: "complete" }
    assert_redirected_to brand_admin_data_commitments_url(@brand.slug, state: "closed", anchor: "data-commitment-#{@brand_request.id}")
    assert_equal "completed", @brand_request.reload.status
    assert @brand_request.resolved_at.present?
    assert_nil @brand_request.starts_at
    assert_not @brand_request.blocks_calendar?

    patch brand_admin_data_commitment_state_url(@brand.slug, @brand_request), params: { transition: "reopen" }
    assert_equal "requested", @brand_request.reload.status
    assert_nil @brand_request.resolved_at
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
