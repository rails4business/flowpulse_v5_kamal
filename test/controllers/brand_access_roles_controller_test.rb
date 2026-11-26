require "test_helper"

class BrandAccessRolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "role-switch-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa",
      role_assignment: @root_assignment,
      operator_roles: %w[imprenditore_generaimpresa]
    )
    @domain = Domain.create!(hostname: "role-switch.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @user = User.create!(email_address: "role-switch-user@example.com", password: "password123")
    @profile = @user.create_profile!(display_name: "Role switch user")
    @access = BrandAccess.create!(profile: @profile, source_domain: @domain)
    @access.create_brand_credential!(
      brand_node: @brand,
      email_address: @user.email_address,
      password: "password123"
    )
    @assignment = RoleAssignment.create!(
      profile: @profile,
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: @brand,
      parent: @root_assignment,
      brand_access: @access
    )
    host! @domain.hostname
    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "selects a valid role belonging to the current brand access" do
    patch dashboard_brand_access_current_role_url(@access), params: { role_assignment_id: @assignment.id }

    assert_redirected_to dashboard_url
    assert_equal @assignment, @access.reload.current_role_assignment
  end

  test "a blank choice retains the only valid role instead of announcing an ordinary user" do
    @access.select_role_assignment!(@assignment)

    patch dashboard_brand_access_current_role_url(@access), params: { role_assignment_id: "" }

    assert_redirected_to dashboard_url
    assert_equal @assignment, @access.reload.current_role_assignment
    assert_equal "Ora operi come Imprenditore GeneraImpresa.", flash[:notice]
  end

  test "cannot select a role belonging to another profile" do
    other_user = User.create!(email_address: "role-switch-other@example.com", password: "password123")
    other_profile = other_user.create_profile!(display_name: "Other")
    other_access = BrandAccess.create!(profile: other_profile, source_domain: @domain)
    other_assignment = RoleAssignment.create!(
      profile: other_profile,
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: @brand,
      parent: @root_assignment,
      brand_access: other_access
    )

    patch dashboard_brand_access_current_role_url(@access), params: { role_assignment_id: other_assignment.id }

    assert_redirected_to dashboard_url
    assert_nil @access.reload.current_role_assignment
    assert_equal "Ruolo non disponibile per questo Brand.", flash[:alert]
  end

  test "clearing a choice with multiple roles requests a new selection" do
    manager = create_manager_assignment
    @access.select_role_assignment!(manager)

    patch dashboard_brand_access_current_role_url(@access), params: { role_assignment_id: "" }

    assert_nil @access.reload.current_role_assignment
    assert_equal "Scegli con quale ruolo operare nel Brand.", flash[:notice]
    context = AccessContext::Resolver.new(user: @user, domain: @domain).resolve
    assert context.selection_required?
    assert_empty context.capabilities
  end

  test "cannot select expired future revoked or disabled roles" do
    [
      { ends_at: 1.minute.ago }, { starts_at: 1.day.from_now },
      { status: "revoked" }, { role_operator: "segreteria" }
    ].each do |attributes|
      @assignment.update_columns(status: "active", starts_at: nil, ends_at: nil,
        role_operator: "imprenditore_generaimpresa", **attributes)
      patch dashboard_brand_access_current_role_url(@access), params: { role_assignment_id: @assignment.id }

      assert_nil @access.reload.current_role_assignment
      assert_equal "Ruolo non disponibile per questo Brand.", flash[:alert]
    end
  end

  test "localhost selects a role using the remembered authentication brand" do
    host! "localhost"
    post session_url, params: { site: @brand.slug, email_address: @user.email_address, password: "password123" }

    patch dashboard_brand_access_current_role_url(@access), params: { role_assignment_id: @assignment.id }

    assert_equal @assignment, @access.reload.current_role_assignment
    assert_equal "Ora operi come Imprenditore GeneraImpresa.", flash[:notice]
  end

  test "host authority prevents selecting an access from another brand" do
    other = Node.create!(title: "PosturaCorretta", slug: "posturacorretta", role_assignment: @root_assignment)
    domain = Domain.create!(hostname: "role-switch-other-brand.example", node: other, role_assignment: @root_assignment)
    access = BrandAccess.create!(profile: @profile, source_domain: domain)

    patch dashboard_brand_access_current_role_url(access), params: { role_assignment_id: @assignment.id, site: "posturacorretta" }

    assert_nil access.reload.current_role_assignment
    assert_equal "Il ruolo scelto non appartiene al Brand corrente.", flash[:alert]
  end

  private

    def create_manager_assignment
      RoleAssignment.create!(profile: @profile, role: :operator, role_operator: "gestore_generaimpresa",
        context: @brand, parent: @root_assignment, brand_access: @access)
    end
end
