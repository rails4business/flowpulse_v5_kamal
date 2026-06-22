require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "sessions-domain-traveler@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @user.create_profile!(display_name: "Traveler")
    creator = User.create!(
      email_address: "sessions-controller-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Login Domain", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "login-domain.example", node: @node, role_assignment: @assignment, locale: "it")
  end

  test "login with subscription domain creates free subscription" do
    assert_difference -> { TravelerSubscription.count }, 1 do
      post session_url, params: {
        email_address: @user.email_address,
        password: "password123",
        subscription_domain_id: @domain.id
      }
    end

    assert @user.profile.traveler_subscriptions.active.exists?(domain: @domain)
    assert_redirected_to root_url
    assert_equal "Ti sei iscritto gratuitamente a login-domain.example.", flash[:notice]
  end
end
