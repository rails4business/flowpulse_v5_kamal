require "test_helper"

class AccessContext::ResolverTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "context-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa-context",
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
    create_assignment("segreteria")

    result = resolve

    assert_equal 2, result.available_role_assignments.size
    assert_nil result.current_role_assignment
    assert result.selection_required?
  end

  test "uses the role selected on the brand access" do
    create_assignment("imprenditore_generaimpresa")
    selected = create_assignment("segreteria")
    @access.select_role_assignment!(selected)

    assert_equal selected, resolve.current_role_assignment
  end

  test "ignores suspended and expired assignments" do
    suspended = create_assignment("imprenditore_generaimpresa")
    suspended.update!(status: "suspended")
    expired = create_assignment("segreteria")
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
