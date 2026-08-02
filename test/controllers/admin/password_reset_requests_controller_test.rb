require "test_helper"

class Admin::PasswordResetRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superadmin = User.create!(email_address: "reset-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
    @user = User.create!(email_address: "reset-request@example.com", password: "password123", password_confirmation: "password123")
    @reset_request = PasswordResetRequest.create!(user: @user, requested_at: Time.current)
    post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
  end

  test "shows a copyable temporary reset link to the superadmin" do
    get admin_password_reset_requests_url

    assert_response :success
    assert_select "input[readonly][value*='/passwords/']", count: 1
    assert_select "button", text: "Copia il link"
    assert_select "aside a[href='#{admin_password_reset_requests_path}']", text: /Reset password/
    assert_select "aside details summary", text: /Cambia sito/
  end

  test "archives a handled request" do
    patch complete_admin_password_reset_request_url(@reset_request)

    assert_redirected_to admin_password_reset_requests_url
    assert_not @reset_request.reload.pending?
  end
end
