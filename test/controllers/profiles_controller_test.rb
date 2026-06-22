require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "profile_test_user@flowpulse.test",
      password: "password123",
      password_confirmation: "password123"
    )
    @profile = Profile.create!(
      user: @user,
      display_name: "Test User Profile",
      first_name: "Test",
      last_name: "User",
      role: "Traveler"
    )
  end

  test "should redirect to session when not authenticated" do
    get profile_url
    assert_redirected_to new_session_url
  end

  test "should get show when authenticated" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    
    get profile_url
    assert_response :success
    assert_includes response.body, "profile_test_user@flowpulse.test"
    assert_includes response.body, "Test User Profile"
    assert_includes response.body, "Traveler"
    assert_includes response.body, @user.id.to_s
    assert_includes response.body, @profile.id.to_s
  end
end
