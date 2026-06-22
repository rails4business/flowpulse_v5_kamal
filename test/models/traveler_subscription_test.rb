require "test_helper"

class TravelerSubscriptionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "traveler-subscription@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @user.create_profile!(display_name: "Traveler")
    creator = User.create!(
      email_address: "traveler-subscription-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Subscribed Node", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "subscribed.example", node: @node, role_assignment: @assignment, locale: "it")
  end

  test "syncs node from domain" do
    subscription = TravelerSubscription.create!(profile: @user.profile, domain: @domain)

    assert_equal @node, subscription.node
    assert_equal "active", subscription.status
    assert subscription.subscribed_at.present?
  end

  test "does not allow domains without node" do
    domain = Domain.create!(hostname: "without-node.example", role_assignment: @assignment, locale: "it")
    subscription = TravelerSubscription.new(profile: @user.profile, domain: domain)

    assert_not subscription.valid?
    assert_includes subscription.errors[:domain_id], "deve essere collegato a un nodo"
  end
end
