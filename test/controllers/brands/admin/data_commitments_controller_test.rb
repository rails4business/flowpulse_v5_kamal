require "test_helper"

class Brands::Admin::DataCommitmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "brand-commitments-owner@example.com", password: "password123", password_confirmation: "password123")
    @profile = @owner.create_profile!(display_name: "Responsabile Brand", username: "responsabile_brand_commitments")
    assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: assignment, title: "Corpo e Coscienza", slug: "corpoecoscienza", status: "published")
    @domain = Domain.create!(hostname: "corpoecoscienza.test", node: @brand, role_assignment: assignment, active: true)
    @commitment = @profile.data_commitments.create!(
      created_by_profile: @profile, domain: @domain, subject: @brand,
      title: "Preparare un incontro", kind: "work", status: "planned",
      starts_at: 2.days.from_now, calendar_key: "brand:#{@brand.id}", calendar_label: "Corpo e Coscienza"
    )
  end

  test "brand admin area requires authentication" do
    get brand_admin_data_commitments_url(@brand.slug)
    assert_redirected_to new_session_url(return_to: brand_admin_data_commitments_path(@brand.slug))
  end

  test "brand owner sees commitments separately from requests" do
    sign_in(@owner)
    get brand_admin_data_commitments_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-nav a[aria-current='page']", text: "Impegni"
    assert_select "h1", "Corpo e Coscienza · Impegni"
    assert_select "#data-commitment-#{@commitment.id}", text: /Preparare un incontro/
    assert_select ".brand-admin-nav a[href='#{brand_admin_requests_path(@brand.slug)}']", text: "Richieste"
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
