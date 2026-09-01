require "test_helper"

class DomainMembershipTest < ActiveSupport::TestCase
  test "has one membership per profile and domain and can be reactivated" do
    user = User.create!(email_address: "membership@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Membership")
    domain = Domain.create!(hostname: "membership.example", target_controller: "landing", target_action: "flowpulse", locale: "it")

    membership = DomainMembership.create!(profile: profile, domain: domain)
    assert membership.active?

    membership.cancel!
    assert_not membership.active?

    membership.reactivate!
    assert membership.active?
    assert_raises ActiveRecord::RecordInvalid do
      DomainMembership.create!(profile: profile, domain: domain)
    end
  end

  test "resolves brand access through profile and domain node without a foreign key" do
    user = User.create!(email_address: "brand-membership@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Brand Membership")
    creator = RoleAssignment.create!(profile: profile, role: :creator_of_worlds)
    node = Node.create!(title: "Membership Brand", role_assignment: creator)
    domain = Domain.create!(hostname: "brand-membership.example", node: node, role_assignment: creator, locale: "it")
    membership = DomainMembership.create!(profile: profile, domain: domain)

    assert_not membership.standalone_domain?
    assert_not membership.brand_access?

    subscription = TravelerSubscription.create!(profile: profile, domain: domain)

    assert_equal subscription, membership.reload.traveler_subscription
    assert membership.brand_access?
  end
end
