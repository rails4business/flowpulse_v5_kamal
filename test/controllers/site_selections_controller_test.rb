require "test_helper"

class SiteSelectionsControllerTest < ActionDispatch::IntegrationTest
  test "an authenticated user can select a local site without admin permissions" do
    user = User.create!(email_address: "site-selection@example.test", password: "password123", password_confirmation: "password123")
    user.create_profile!(display_name: "Site Selection", username: "site_selection")
    domain = Domain.create!(hostname: "posturacorretta.org", target_controller: "landing", target_action: "posturacorretta", locale: "it", active: true)

    host! "localhost"
    post session_path, params: { email_address: user.email_address, password: "password123" }
    post site_selection_path, params: { domain_id: domain.id }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_includes response.body, "PosturaCorretta"
  end
end
