require "test_helper"

class BrandAccesses::ManagerTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "access-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    node = Node.create!(title: "Brand", role_assignment: assignment)
    @domain = Domain.create!(hostname: "access-manager.example", node: node, role_assignment: assignment, locale: "it")
    person = User.create!(email_address: "access-person@example.com", password: "password123")
    @profile = person.create_profile!(display_name: "Person")
    @superadmin = User.create!(email_address: "access-superadmin@example.com", password: "password123", superadmin: true)
  end

  test "grants revokes and reactivates the same access" do
    manager = BrandAccesses::Manager.new(actor: @superadmin)
    access = manager.grant!(profile: @profile, domain: @domain)
    assert access.active?

    manager.revoke!(access)
    assert_equal "cancelled", access.reload.status

    assert_no_difference -> { BrandAccess.count } do
      assert_equal access, manager.grant!(profile: @profile, domain: @domain)
    end
    assert access.reload.active?
  end
end
