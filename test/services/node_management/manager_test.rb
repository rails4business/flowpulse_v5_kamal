require "test_helper"

class NodeManagement::ManagerTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "node-manager-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(title: "GeneraImpresa", slug: "generaimpresa", role_assignment: @root_assignment, operator_roles: %w[imprenditore_generaimpresa])
    domain = Domain.create!(hostname: "node-manager.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @user = User.create!(email_address: "node-manager-entrepreneur@example.com", password: "password123")
    @user.create_profile!(display_name: "Entrepreneur")
    access = BrandAccess.create!(profile: @user.profile, source_domain: domain)
    @project = Node.create!(title: "Assigned project", parent: @brand, role_assignment: @root_assignment, responsible_profile: @user.profile)
    RoleAssignment.create!(profile: @user.profile, role: :operator, role_operator: "imprenditore_generaimpresa", context: @project, parent: @root_assignment, brand_access: access)
  end

  test "creates a private draft child assigned to the entrepreneur" do
    node = manager.create_child!(parent: @project, attributes: { title: "New child", description: "Test", status: "draft", visibility: "private" })

    assert_equal @project, node.parent
    assert_equal @user.profile, node.responsible_profile
    assert_equal @root_assignment, node.role_assignment
    assert node.project?
    assert_equal "private", node.visibility
  end

  test "rejects creation after seven responsible nodes" do
    6.times do |index|
      Node.create!(title: "Existing #{index}", parent: @project, role_assignment: @root_assignment, responsible_profile: @user.profile)
    end

    assert_raises(NodeManagement::Manager::NotAuthorized) do
      manager.create_child!(parent: @project, attributes: { title: "Eighth" })
    end
  end

  test "rejects updates outside the assigned branch" do
    outside = Node.create!(title: "Outside", parent: @brand, role_assignment: @root_assignment)

    assert_raises(NodeManagement::Manager::NotAuthorized) do
      manager.update!(node: outside, attributes: { title: "Changed" })
    end
    assert_equal "Outside", outside.reload.title
  end

  test "a standalone call without explicit context cannot create a node" do
    assert_no_difference -> { Node.count } do
      assert_raises(NodeManagement::Manager::NotAuthorized) do
        NodeManagement::Manager.new(actor: @user).create_child!(parent: @project, attributes: { title: "Without context" })
      end
    end
  end

  private

    def manager
      NodeManagement::Manager.new(actor: @user,
        context: AccessContext::Resolver.new(user: @user, domain: @brand.domains.first).resolve)
    end
end
