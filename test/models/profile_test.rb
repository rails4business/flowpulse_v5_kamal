require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "profile-test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "automatically generates unique username on creation" do
    profile = @user.create_profile!(display_name: "John Doe")
    assert_equal "profile_test", profile.username

    # Create another user and profile with same email prefix
    user2 = User.create!(
      email_address: "profile-test@example.com.org",
      password: "password123",
      password_confirmation: "password123"
    )
    profile2 = user2.create_profile!(display_name: "Jane Doe")
    assert_equal "profile_test_1", profile2.username
  end

  test "validates username format" do
    profile = @user.build_profile(display_name: "Test", username: "invalid-username")
    assert_not profile.valid?
    assert_includes profile.errors[:username], "può contenere solo lettere, numeri e underscore (_)"

    profile.username = "valid_username_123"
    assert profile.valid?
  end

  test "validates username length" do
    profile = @user.build_profile(display_name: "Test", username: "ab")
    assert_not profile.valid?
    assert_includes profile.errors[:username], "is too short (minimum is 3 characters)"

    profile.username = "a" * 31
    assert_not profile.valid?
    assert_includes profile.errors[:username], "is too long (maximum is 30 characters)"
  end

  test "normalizes username to lowercase" do
    profile = @user.create_profile!(display_name: "Test", username: "MY_UserNAME")
    assert_equal "my_username", profile.username
  end
end
