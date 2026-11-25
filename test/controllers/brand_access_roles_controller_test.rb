require "test_helper"

class BrandAccessRolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "role-switch-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa-role-switch",
      role_assignment: @root_assignment,
      operator_roles: %w[imprenditore_generaimpresa]
    )
    @domain = Domain.create!(hostname: "role-switch.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @user = User.create!(email_address: "role-switch-user@example.com", password: "password123")
    @profile = @user.create_profile!(display_name: "Role switch user")
    @access = BrandAccess.create!(profile: @profile, source_domain: @domain)
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

  test "clears the selected role to operate as a brand user" do
    @access.select_role_assignment!(@assignment)

    patch dashboard_brand_access_current_role_url(@access), params: { role_assignment_id: "" }

    assert_redirected_to dashboard_url
    assert_nil @access.reload.current_role_assignment
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
end
