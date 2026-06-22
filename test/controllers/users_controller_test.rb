require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    creator = User.create!(
      email_address: "users-controller-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Registration Domain", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "registration-domain.example", node: @node, role_assignment: @assignment, locale: "it")
  end

  test "registration with subscription domain creates profile and free subscription" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { TravelerSubscription.count }, 1 do
        post users_url, params: {
          subscription_domain_id: @domain.id,
          user: {
            email_address: "new-domain-traveler@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
    end

    user = User.find_by!(email_address: "new-domain-traveler@example.com")
    assert_equal "traveler", user.active_role
    assert user.profile.present?
    assert user.profile.traveler_subscriptions.active.exists?(domain: @domain)
    assert_redirected_to root_url
    assert_equal "Registrazione completata. Ti sei iscritto gratuitamente a registration-domain.example.", flash[:notice]
  end
end
