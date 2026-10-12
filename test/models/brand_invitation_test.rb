require "test_helper"

class BrandInvitationTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email_address: "invitation-owner@example.com", password: "password123")
    @owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: @owner.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Invitation Brand", role_assignment: assignment)
    @domain = Domain.create!(hostname: "invitation.example", node: @node, role_assignment: assignment)
  end

  test "only the invited email can accept a brand invitation" do
    invitation, raw_token = BrandInvitation.issue!(
      brand_node: @node,
      source_domain: @domain,
      email_address: "invited@example.com",
      invited_by_user: @owner
    )
    invited = User.create!(email_address: "invited@example.com", password: "password123")

    assert_equal invitation, BrandInvitation.find_pending_by_token(raw_token)
    invitation.accept!(invited)
    assert_equal "accepted", invitation.status
    assert_equal invited, invitation.accepted_by_user
  end
end
