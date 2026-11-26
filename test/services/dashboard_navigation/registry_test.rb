require "test_helper"

class DashboardNavigation::RegistryTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email_address: "navigation-owner@example.com", password: "password123")
    @owner.create_profile!(display_name: "Owner")
    @root_role = RoleAssignment.create!(profile: @owner.profile, role: :ideatore)
    @brand = Node.create!(title: "GeneraImpresa", slug: "generaimpresa", role_assignment: @root_role)
    @domain = Domain.create!(hostname: "navigation.example", node: @brand, role_assignment: @root_role)
    @user = User.create!(email_address: "navigation-person@example.com", password: "password123")
    @profile = @user.create_profile!(display_name: "Person")
    @access = BrandAccess.create!(profile: @profile, source_domain: @domain)
  end

  test "ordinary Brand users have no administrative sections" do
    registry = registry_for(@user)

    assert_empty registry.sections
    assert_equal %i[brand_home profile], registry.sidebar.map(&:key)
  end

  test "revocation makes a previously resolved navigation context ineffective" do
    create_role("gestore_generaimpresa", @brand)
    registry = registry_for(@user)
    assert_equal %i[requests brand_people projects], registry.sections.map(&:key)

    @access.cancel!

    assert_empty registry.sections
    assert_not_includes registry.sidebar.map(&:key), :brand_dashboard
  end

  test "a manager assigned to a project does not receive whole Brand sections" do
    project = Node.create!(title: "Limited project", parent: @brand, role_assignment: @root_role)
    create_role("gestore_generaimpresa", project)

    assert_equal [:projects], registry_for(@user).sections.map(&:key)
  end

  test "global navigation preserves every legacy destination in the main index" do
    superadmin = User.create!(email_address: "navigation-superadmin@example.com", password: "password123", superadmin: true)
    context = AccessContext::Resolver.new(user: superadmin, domain: nil).resolve
    registry = DashboardNavigation::Registry.new(context: context)
    paths = registry.sections.map(&:path)

    FlowRoles::MenuRegistry.items.reject { |item| item.key == :dashboard }.each do |item|
      expected = item.path.is_a?(Symbol) ? Rails.application.routes.url_helpers.public_send(item.path) : item.path
      assert_includes paths, expected
    end
    assert_equal paths.uniq, paths
    assert_includes registry.sections.map(&:key), :profiles
    assert_equal %i[brand_home brand_dashboard], registry.sidebar.map(&:key)
  end

  test "shared navigation applies to other Brands without introducing administrative roles" do
    other = Node.create!(title: "PosturaCorretta", slug: "posturacorretta", role_assignment: @root_role)
    domain = Domain.create!(hostname: "navigation-postura.example", node: other, role_assignment: @root_role)
    access = BrandAccess.create!(profile: @profile, source_domain: domain)
    RoleAssignment.create!(profile: @profile, role: :operator, role_operator: "insegnante_posturacorretta",
      context: other, parent: @root_role, brand_access: access)
    context = AccessContext::Resolver.new(user: @user, domain: domain).resolve

    assert DashboardAside::Builder.new(context: context).applicable?
    assert_empty DashboardNavigation::Registry.new(context: context).sections
    assert_not DashboardNavigation::Policy.new(context: context).allowed?(:nodes)
  end

  private

    def create_role(code, node)
      RoleAssignment.create!(profile: @profile, role: :operator, role_operator: code,
        context: node, parent: @root_role, brand_access: @access)
    end

    def registry_for(user)
      DashboardNavigation::Registry.new(context: AccessContext::Resolver.new(user: user, domain: @domain).resolve)
    end
end
