require "test_helper"

class Brands::Admin::PrivacyControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "brand-privacy-owner@example.com", password: "password123", password_confirmation: "password123")
    profile = @owner.create_profile!(display_name: "Brand Privacy Owner")
    role = RoleAssignment.create!(profile: profile, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: role, title: "Corpo e Coscienza", slug: "corpoecoscienza", status: "published")
    Domain.create!(hostname: "corpoecoscienza.org", node: @brand, role_assignment: role, active: true)
  end

  test "brand privacy area requires authentication" do
    get brand_admin_privacy_url(@brand.slug)

    assert_redirected_to new_session_url(return_to: brand_admin_privacy_path(@brand.slug))
  end

  test "brand owner sees default checklist and active domain configuration" do
    post session_url, params: { email_address: @owner.email_address, password: "password123" }
    get brand_admin_privacy_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-nav a[aria-current='page']", text: "Privacy"
    assert_select "h1", "Corpo e Coscienza · Privacy"
    assert_select "li", text: /Titolare e contatti/
    assert_select "strong", text: "corpoecoscienza.org"
    assert_select "a[href='#{corpo_e_coscienza_privacy_path}']", text: /Apri informativa/
    assert_select "li", text: /Leaflet, OpenStreetMap/
  end
end
