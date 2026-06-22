require "test_helper"

class TravelerSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "traveler-subscriptions-controller@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    @user.create_profile!(display_name: "Traveler")
    creator = User.create!(
      email_address: "traveler-subscriptions-controller-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Domain Node", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "subscribe-controller.example", node: @node, role_assignment: @assignment, locale: "it")
  end

  test "traveler can subscribe and unsubscribe to domain" do
    sign_in(@user)

    assert_difference -> { TravelerSubscription.count }, 1 do
      post traveler_subscriptions_url, params: { domain_id: @domain.id }
    end

    subscription = @user.profile.traveler_subscriptions.find_by!(domain: @domain)
    assert_equal @node, subscription.node
    assert_equal "active", subscription.status
    assert_redirected_to viaggiatori_url
    assert_equal "Ti sei iscritto gratuitamente a subscribe-controller.example.", flash[:notice]

    delete traveler_subscription_url(subscription)

    assert_redirected_to viaggiatori_url
    assert_equal "Hai rimosso l'iscrizione a subscribe-controller.example.", flash[:notice]
    assert_equal "cancelled", subscription.reload.status
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
