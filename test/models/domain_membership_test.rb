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
end
