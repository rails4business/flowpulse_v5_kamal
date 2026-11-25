require "test_helper"

class RoleAssignments::AccessPolicyTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "policy-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa",
      role_assignment: @root_assignment,
      operator_roles: %w[imprenditore_generaimpresa]
    )
    domain = Domain.create!(hostname: "policy-generaimpresa.example", node: @brand, role_assignment: @root_assignment, locale: "it")

    @entrepreneur = User.create!(email_address: "policy-entrepreneur@example.com", password: "password123")
    @entrepreneur.create_profile!(display_name: "Entrepreneur")
    @entrepreneur_access = BrandAccess.create!(profile: @entrepreneur.profile, source_domain: domain)
    @project = Node.create!(title: "Assigned project", parent: @brand, role_assignment: @root_assignment, responsible_profile: @entrepreneur.profile)
    RoleAssignment.create!(
      profile: @entrepreneur.profile,
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: @project,
      parent: @root_assignment,
      brand_access: @entrepreneur_access,
      status: "active"
    )
    @child = Node.create!(title: "Project child", parent: @project, role_assignment: @root_assignment)
    @outside_project = Node.create!(title: "Outside project", parent: @brand, role_assignment: @root_assignment)

    recipient = User.create!(email_address: "policy-recipient@example.com", password: "password123")
    @recipient_profile = recipient.create_profile!(display_name: "Recipient")
    BrandAccess.create!(profile: @recipient_profile, source_domain: domain)
    @superadmin = User.create!(email_address: "policy-superadmin@example.com", password: "password123", superadmin: true)
  end

  test "allows an entrepreneur to manage the assigned project and descendants only" do
    assert policy.allowed?(user: @entrepreneur, action: :manage, node: @project)
    assert policy.allowed?(user: @entrepreneur, action: :manage, node: @child)
    assert_not policy.allowed?(user: @entrepreneur, action: :manage, node: @outside_project)
  end

  test "allows six additional responsible nodes after the assigned project and rejects the eighth" do
    5.times do |index|
      Node.create!(title: "Managed #{index}", parent: @project, role_assignment: @root_assignment, responsible_profile: @entrepreneur.profile)
    end
    assert policy.can_create_node?(user: @entrepreneur, parent: @project)

    Node.create!(title: "Managed sixth", parent: @project, role_assignment: @root_assignment, responsible_profile: @entrepreneur.profile)
    assert_equal 7, @entrepreneur.profile.responsible_nodes.count
    assert_not policy.can_create_node?(user: @entrepreneur, parent: @project)
  end

  test "does not allow the entrepreneur to delegate roles yet" do
    assert_not policy.can_assign_role?(user: @entrepreneur, recipient_profile: @recipient_profile, role_code: "segreteria", node: @project)
    assert_not policy.can_assign_role?(user: @entrepreneur, recipient_profile: @recipient_profile, role_code: "imprenditore_generaimpresa", node: @project)
  end

  test "keeps the superadmin unrestricted" do
    assert policy.allowed?(user: @superadmin, action: :manage, node: @outside_project)
    assert policy.can_create_node?(user: @superadmin, parent: @outside_project)
    assert policy.can_assign_role?(user: @superadmin, recipient_profile: @recipient_profile, role_code: "imprenditore_generaimpresa", node: @outside_project)
  end

  test "the unified manager rejects role assignment by the entrepreneur" do
    assert_raises(RoleAssignments::Manager::NotAuthorized) do
      RoleAssignments::Manager.new(actor: @entrepreneur).assign_operator!(
        profile: @recipient_profile,
        brand_access: @recipient_profile.brand_accesses.active.first,
        node: @project,
        role_code: "segreteria"
      )
    end
  end

  private

    def policy
      RoleAssignments::AccessPolicy
    end
end
