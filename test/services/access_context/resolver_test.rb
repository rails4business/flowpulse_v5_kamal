require "test_helper"

class AccessContext::ResolverTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "context-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa",
      role_assignment: @root_assignment,
      operator_roles: %w[imprenditore_generaimpresa gestore_generaimpresa]
    )
    @domain = Domain.create!(
      hostname: "context-generaimpresa.example",
      node: @brand,
      role_assignment: @root_assignment,
      locale: "it"
    )
    @user = User.create!(email_address: "context-user@example.com", password: "password123")
    @profile = @user.create_profile!(display_name: "Context user")
    @access = BrandAccess.create!(profile: @profile, source_domain: @domain)
  end

  test "returns an ordinary brand user when there are no assignments" do
    result = resolve

    assert_equal @brand, result.brand
    assert_equal @access, result.brand_access
    assert_empty result.available_role_assignments
    assert_nil result.current_role_assignment
    assert result.user?
    assert_not result.selection_required?
  end

  test "automatically resolves the only valid assignment" do
    assignment = create_assignment("imprenditore_generaimpresa")

    result = resolve

    assert_equal [assignment], result.available_role_assignments
    assert_equal assignment, result.current_role_assignment
    assert_not result.user?
  end

  test "requires a selection when multiple assignments exist and none is current" do
    create_assignment("imprenditore_generaimpresa")
    create_assignment("gestore_generaimpresa")

    result = resolve

    assert_equal 2, result.available_role_assignments.size
    assert_nil result.current_role_assignment
    assert result.selection_required?
    assert_not result.user?
    assert_empty result.capabilities
  end

  test "uses the role selected on the brand access" do
    create_assignment("imprenditore_generaimpresa")
    selected = create_assignment("gestore_generaimpresa")
    @access.select_role_assignment!(selected)

    assert_equal selected, resolve.current_role_assignment
  end

  test "ignores suspended and expired assignments" do
    suspended = create_assignment("imprenditore_generaimpresa")
    suspended.update!(status: "suspended")
    expired = create_assignment("gestore_generaimpresa")
    expired.update!(ends_at: 1.minute.ago)

    result = resolve

    assert_empty result.available_role_assignments
    assert_nil result.current_role_assignment
  end

  test "does not use an access belonging to another domain" do
    other_brand = Node.create!(title: "Other", slug: "other-context", role_assignment: @root_assignment)
    other_domain = Domain.create!(hostname: "other-context.example", node: other_brand, role_assignment: @root_assignment, locale: "it")

    result = described_class.new(user: @user, domain: other_domain).resolve

    assert_nil result.brand_access
    assert_empty result.available_role_assignments
  end

  test "marks the global system privilege independently from brand roles" do
    superadmin = User.create!(email_address: "context-superadmin@example.com", password: "password123", superadmin: true)

    result = described_class.new(user: superadmin, domain: @domain).resolve

    assert result.superadmin?
    assert_nil result.brand_access
  end

  test "historical disabled or incompatible definitions do not grant capabilities" do
    assignment = create_assignment("imprenditore_generaimpresa")
    assignment.update_columns(role_operator: "segreteria")
    assert_empty resolve.capabilities

    assignment.update_columns(role_operator: "insegnante_posturacorretta")
    assert_empty resolve.capabilities
  end

  test "a visitor without an active brand access is not an ordinary brand user" do
    @access.cancel!
    result = resolve

    assert result.guest?
    assert_not result.user?
    assert_nil result.brand_access
    assert_empty result.capabilities
  end

  test "inactive domains and suspended accounts do not produce an operational context" do
    create_assignment("imprenditore_generaimpresa")
    @domain.update!(active: false)
    assert resolve.guest?
    assert_empty resolve.available_role_assignments

    @domain.update!(active: true)
    @user.update!(registration_status: "suspended")
    assert resolve.guest?
    assert_empty resolve.capabilities
  end

  test "future assignments and expired selected assignments are excluded" do
    selected = create_assignment("imprenditore_generaimpresa")
    @access.select_role_assignment!(selected)
    selected.update!(ends_at: 1.minute.ago)
    future = create_assignment("gestore_generaimpresa")
    future.update!(starts_at: 1.day.from_now)

    assert_empty resolve.available_role_assignments
    assert_nil resolve.current_role_assignment
    assert_empty resolve.capabilities
  end

  test "revocation replaces the effective selection with the sole remaining valid role" do
    selected = create_assignment("gestore_generaimpresa")
    remaining = create_assignment("imprenditore_generaimpresa")
    @access.select_role_assignment!(selected)
    selected.update!(status: "revoked")

    result = resolve

    assert_equal remaining, result.current_role_assignment
    assert_not result.capability?(:manage_requests)
    assert result.capability?(:create_children)
  end

  test "role selection changes capabilities without combining the two roles" do
    manager = create_assignment("gestore_generaimpresa")
    entrepreneur = create_assignment("imprenditore_generaimpresa")
    @access.select_role_assignment!(manager)

    assert resolve.capability?(:manage_requests)
    assert_not resolve.capability?(:create_children)

    @access.select_role_assignment!(entrepreneur)

    assert_not resolve.capability?(:manage_requests)
    assert resolve.capability?(:create_children)
  end

  test "assignments with another profile or outside the brand are excluded" do
    assignment = create_assignment("imprenditore_generaimpresa")
    outside = Node.create!(title: "Outside context", role_assignment: @root_assignment)
    assignment.update_columns(context_id: outside.id)
    assert_empty resolve.available_role_assignments

    assignment.update_columns(context_id: @brand.id, profile_id: @root_assignment.profile_id)
    assert_empty resolve.available_role_assignments
  end

  test "a nested brand is a separate context even inside the node tree" do
    assignment = create_assignment("imprenditore_generaimpresa")
    nested = Node.create!(title: "Nested Brand", parent: @brand, role_assignment: @root_assignment)
    Domain.create!(hostname: "nested-context.example", node: nested, role_assignment: @root_assignment)
    assignment.update_columns(context_id: nested.id)

    assert_empty resolve.available_role_assignments
    assert_empty resolve.capabilities
  end

  test "a domain alias shares the same access and selection" do
    selected = create_assignment("gestore_generaimpresa")
    @access.select_role_assignment!(selected)
    alias_domain = Domain.create!(hostname: "alias-context.example", canonical_host: @domain.hostname,
      node: @brand, role_assignment: @root_assignment)

    result = described_class.new(user: @user, domain: alias_domain).resolve

    assert_equal @domain, result.domain
    assert_equal @access, result.brand_access
    assert_equal selected, result.current_role_assignment
  end

  private

    def described_class
      AccessContext::Resolver
    end

    def resolve
      described_class.new(user: @user, domain: @domain).resolve
    end

    def create_assignment(role_code)
      RoleAssignment.create!(
        profile: @profile,
        role: :operator,
        role_operator: role_code,
        context: @brand,
        parent: @root_assignment,
        brand_access: @access
      )
    end
end
