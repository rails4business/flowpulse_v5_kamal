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
    @domain = Domain.create!(hostname: "policy-generaimpresa.example", node: @brand, role_assignment: @root_assignment, locale: "it")

    @entrepreneur = User.create!(email_address: "policy-entrepreneur@example.com", password: "password123")
    @entrepreneur.create_profile!(display_name: "Entrepreneur")
    @entrepreneur_access = BrandAccess.create!(profile: @entrepreneur.profile, source_domain: @domain)
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
    BrandAccess.create!(profile: @recipient_profile, source_domain: @domain)
    @superadmin = User.create!(email_address: "policy-superadmin@example.com", password: "password123", superadmin: true)
  end

  test "allows an entrepreneur to manage the assigned project and descendants only" do
    assert policy.allowed?(user: @entrepreneur, action: :manage, node: @project, context: context)
    assert policy.allowed?(user: @entrepreneur, action: :manage, node: @child, context: context)
    assert_not policy.allowed?(user: @entrepreneur, action: :manage, node: @outside_project, context: context)
  end

  test "allows six additional responsible nodes after the assigned project and rejects the eighth" do
    5.times do |index|
      Node.create!(title: "Managed #{index}", parent: @project, role_assignment: @root_assignment, responsible_profile: @entrepreneur.profile)
    end
    assert policy.can_create_node?(user: @entrepreneur, parent: @project, context: context)

    Node.create!(title: "Managed sixth", parent: @project, role_assignment: @root_assignment, responsible_profile: @entrepreneur.profile)
    assert_equal 7, @entrepreneur.profile.responsible_nodes.count
    assert_not policy.can_create_node?(user: @entrepreneur, parent: @project, context: context)
  end

  test "does not allow the entrepreneur to delegate roles yet" do
    assert_not policy.can_assign_role?(user: @entrepreneur, recipient_profile: @recipient_profile, role_code: "segreteria", node: @project, context: context)
    assert_not policy.can_assign_role?(user: @entrepreneur, recipient_profile: @recipient_profile, role_code: "imprenditore_generaimpresa", node: @project, context: context)
  end

  test "keeps the superadmin unrestricted" do
    assert policy.allowed?(user: @superadmin, action: :manage, node: @outside_project)
    assert policy.can_create_node?(user: @superadmin, parent: @outside_project)
    assert policy.can_assign_role?(user: @superadmin, recipient_profile: @recipient_profile, role_code: "imprenditore_generaimpresa", node: @outside_project)
  end

  test "the unified manager rejects role assignment by the entrepreneur" do
    assert_raises(RoleAssignments::Manager::NotAuthorized) do
      RoleAssignments::Manager.new(actor: @entrepreneur, context: context).assign_operator!(
        profile: @recipient_profile,
        brand_access: @recipient_profile.brand_accesses.active.first,
        node: @project,
        role_code: "segreteria"
      )
    end
  end

  test "historical disabled or incompatible roles cannot grant capabilities" do
    assignment = @entrepreneur.profile.role_assignments.find_by!(role: :operator)
    assignment.update_columns(role_operator: "segreteria")
    assert_not policy.allowed?(user: @entrepreneur, action: :manage_office, node: @project, context: context)

    assignment.update_columns(role_operator: "insegnante_posturacorretta")
    assert_not policy.allowed?(user: @entrepreneur, action: :teach, node: @project, context: context)
  end

  test "a task must supply context instead of selecting a brand through the target node" do
    assert_not policy.allowed?(user: @entrepreneur, action: :manage, node: @project)
    assert policy.allowed?(user: @entrepreneur, action: :manage, node: @project, context: context)
  end

  test "only the selected role authorizes operations and old snapshots are rejected" do
    manager = RoleAssignment.create!(profile: @entrepreneur.profile, role: :operator,
      role_operator: "gestore_generaimpresa", context: @brand, parent: @root_assignment, brand_access: @entrepreneur_access)
    assert_not policy.allowed?(user: @entrepreneur, action: :manage_requests, node: @project, context: context)
    entrepreneur = @entrepreneur.profile.role_assignments.find_by!(role_operator: "imprenditore_generaimpresa")
    @entrepreneur_access.select_role_assignment!(entrepreneur)
    old_context = context
    assert policy.can_create_node?(user: @entrepreneur, parent: @project, context: old_context)
    assert_not policy.allowed?(user: @entrepreneur, action: :manage_requests, node: @project, context: old_context)

    @entrepreneur_access.select_role_assignment!(manager)

    assert_not policy.can_create_node?(user: @entrepreneur, parent: @project, context: old_context)
    assert_not policy.can_create_node?(user: @entrepreneur, parent: @project, context: context)
    assert policy.allowed?(user: @entrepreneur, action: :manage_requests, node: @project, context: context)
  end

  test "a revoked access or expired role invalidates a previously resolved context" do
    old_context = context
    role = old_context.current_role_assignment
    role.update!(ends_at: 1.minute.ago)
    assert_not policy.allowed?(user: @entrepreneur, action: :manage, node: @project, context: old_context)

    role.update!(ends_at: nil)
    @entrepreneur_access.cancel!
    assert_not policy.allowed?(user: @entrepreneur, action: :manage, node: @project, context: old_context)
  end

  test "inheritance cannot cross a nested brand root" do
    nested = Node.create!(title: "Nested Brand", parent: @project, role_assignment: @root_assignment)
    Domain.create!(hostname: "nested-policy.example", node: nested, role_assignment: @root_assignment)

    assert_not policy.allowed?(user: @entrepreneur, action: :manage, node: nested, context: context)
    assert_not policy.can_create_node?(user: @entrepreneur, parent: nested, context: context)
  end

  test "a context belonging to another actor cannot authorize an operation" do
    other = AccessContext::Resolver.new(user: @recipient_profile.user, domain: @domain).resolve

    assert_not policy.allowed?(user: @entrepreneur, action: :manage, node: @project, context: other)
  end

  test "a temporary delegation rule permits assignment only in the current branch and never implies revocation" do
    registry = RoleDefinitions::Registry
    definition = registry.fetch("imprenditore_generaimpresa").with(delegatable_role_codes: ["gestore_generaimpresa"])
    definitions = registry::DEFINITIONS.merge(definition.code => definition).freeze

    stub_const(registry, :DEFINITIONS, definitions) do
      role_manager = RoleAssignments::Manager.new(actor: @entrepreneur, context: context)
      assignment = role_manager.assign_operator!(profile: @recipient_profile,
        brand_access: @recipient_profile.brand_accesses.first, node: @project, role_code: "gestore_generaimpresa")

      assert_equal @entrepreneur.profile, assignment.assigned_by_profile
      assert_equal ["assigned"], assignment.audit_log.pluck("event")
      assert_not policy.can_assign_role?(user: @entrepreneur, recipient_profile: @recipient_profile,
        role_code: "gestore_generaimpresa", node: @outside_project, context: context)
      assert_raises(RoleAssignments::Manager::NotAuthorized) { role_manager.revoke!(assignment) }

      @recipient_profile.brand_accesses.first.cancel!
      assert_not policy.can_assign_role?(user: @entrepreneur, recipient_profile: @recipient_profile,
        role_code: "gestore_generaimpresa", node: @project, context: context)
    end

    assert_empty registry.fetch("imprenditore_generaimpresa").delegatable_role_codes
  end

  private

    def policy
      RoleAssignments::AccessPolicy
    end

    def context
      AccessContext::Resolver.new(user: @entrepreneur, domain: @domain).resolve
    end
end
