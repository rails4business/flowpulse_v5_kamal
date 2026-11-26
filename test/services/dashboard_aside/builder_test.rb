require "test_helper"

class DashboardAside::BuilderTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "aside-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa",
      role_assignment: @root_assignment,
      operator_roles: %w[gestore_generaimpresa imprenditore_generaimpresa]
    )
    @domain = Domain.create!(hostname: "aside-generaimpresa.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @user = User.create!(email_address: "aside-user@example.com", password: "password123")
    @profile = @user.create_profile!(display_name: "Aside user")
    @access = BrandAccess.create!(profile: @profile, source_domain: @domain)
  end

  test "shows only the public brand space and profile to an ordinary brand user" do
    keys = item_keys_for(@user)

    assert_equal %i[genera_impresa_home profile], keys
  end

  test "shows requests and projects to a GeneraImpresa manager" do
    create_assignment("gestore_generaimpresa")

    keys = item_keys_for(@user)

    assert_includes keys, :genera_impresa_requests
    assert_includes keys, :genera_impresa_people
    assert_includes keys, :genera_impresa_projects
    assert_not_includes keys, :flowpulse_admin
  end

  test "limits an entrepreneur to project navigation" do
    create_assignment("imprenditore_generaimpresa")

    keys = item_keys_for(@user)

    assert_includes keys, :genera_impresa_projects
    assert_not_includes keys, :genera_impresa_requests
  end

  test "adds the global administration link only for the superadmin" do
    superadmin = User.create!(email_address: "aside-superadmin@example.com", password: "password123", superadmin: true)

    items = items_for(superadmin)
    keys = items.map(&:key)

    assert_includes keys, :genera_impresa_requests
    assert_includes keys, :flowpulse_admin
    assert_equal :canonical_flowpulse_admin_dashboard_url, items.find { |item| item.key == :flowpulse_admin }.path
  end

  test "reduces the FlowPulse superadmin aside to the administration entry" do
    flowpulse = Node.create!(title: "FlowPulse", slug: "flowpulse", role_assignment: @root_assignment)
    domain = Domain.create!(hostname: "aside-flowpulse.example", node: flowpulse, role_assignment: @root_assignment, locale: "it")
    superadmin = User.create!(email_address: "aside-flowpulse-superadmin@example.com", password: "password123", superadmin: true)
    context = AccessContext::Resolver.new(user: superadmin, domain:).resolve

    keys = described_class.new(context:).groups.fetch(:brand).map(&:key)

    assert_equal %i[flowpulse_home flowpulse_administration flowpulse_profiles], keys
  end

  test "navigation follows the selected role without combining all assigned roles" do
    manager = create_assignment("gestore_generaimpresa")
    entrepreneur = create_assignment("imprenditore_generaimpresa")
    assert_not_includes item_keys_for(@user), :genera_impresa_requests

    @access.select_role_assignment!(manager)
    assert_includes item_keys_for(@user), :genera_impresa_requests

    @access.select_role_assignment!(entrepreneur)
    assert_not_includes item_keys_for(@user), :genera_impresa_requests
    assert_includes item_keys_for(@user), :genera_impresa_projects
  end

  private

    def item_keys_for(user)
      items_for(user).map(&:key)
    end

    def items_for(user)
      context = AccessContext::Resolver.new(user:, domain: @domain).resolve
      described_class.new(context:).groups.fetch(:brand)
    end

    def described_class
      DashboardAside::Builder
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
