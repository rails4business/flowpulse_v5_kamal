require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "manual-reset@example.com", password: "password123", password_confirmation: "password123")
  end

  test "creates a manual reset request without sending an email" do
    assert_difference -> { PasswordResetRequest.count }, 1 do
      post passwords_url, params: { email_address: @user.email_address }
    end

    assert_redirected_to new_session_url
    assert_equal @user, PasswordResetRequest.last.user
    assert PasswordResetRequest.last.pending?
  end

  test "does not disclose whether an email exists" do
    assert_no_difference -> { PasswordResetRequest.count } do
      post passwords_url, params: { email_address: "missing@example.com" }
    end

    assert_redirected_to new_session_url
  end

  test "returns an authenticated user to the profile after requesting a reset" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    post passwords_url, params: { email_address: @user.email_address }

    assert_redirected_to profile_url
  end
end
