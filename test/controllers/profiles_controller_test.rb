require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "profile-email@example.com", password: "password123", password_confirmation: "password123")
    @user.create_profile!(display_name: "Profile Email", username: "profile_email")
    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "updates the email after a recent password reset" do
    @user.update!(email_change_authorized_at: Time.current)

    patch profile_url, params: { user: { email_address: "nuova-email@example.com" } }

    assert_redirected_to profile_url
    assert_equal "nuova-email@example.com", @user.reload.email_address
  end

  test "opens the email update form from the email button" do
    get profile_url

    assert_response :success
    assert_select "button[commandfor='edit-email-dialog']", text: "profile-email@example.com"
    assert_select "dialog#edit-email-dialog input[name='user[email_address]']", count: 0
    assert_select "dialog#edit-email-dialog", text: /Per sicurezza l’email si modifica solo subito dopo/
    assert_select "a[href*='#{new_password_path}']", text: "Reimposta password", count: 1
    assert_select "a[href*='email_address=profile-email%40example.com'][href*='user_id=#{@user.id}'][href*='profile_id=#{@user.profile.id}']", text: "Reimposta password"
  end

  test "does not update the email without a recent password reset" do
    patch profile_url, params: { user: { email_address: "non-deve-cambiare@example.com" } }

    assert_response :unprocessable_entity
    assert_equal "profile-email@example.com", @user.reload.email_address
    assert_includes response.body, "Per modificare l’email, reimposta prima la password"
  end

  test "updates editable profile details" do
    patch details_profile_url, params: { profile: { display_name: "Marco", first_name: "Marco", last_name: "Beffa", username: "marco_beffa" } }

    assert_redirected_to profile_url
    assert_equal ["Marco", "Marco", "Beffa", "marco_beffa"], @user.profile.reload.attributes.values_at("display_name", "first_name", "last_name", "username")
  end
end
