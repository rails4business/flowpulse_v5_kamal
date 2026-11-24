require "test_helper"

class Admin::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(
      email_address: "genera-owner-#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
    owner_profile = owner.create_profile!(display_name: "Ideatore GeneraImpresa", username: "genera_owner_#{SecureRandom.hex(3)}")
    @brand_assignment = RoleAssignment.create!(profile: owner_profile, role: :ideatore)
    @brand = Node.create!(
      role_assignment: @brand_assignment,
      title: "GeneraImpresa",
      slug: "generaimpresa",
      node_type: "project",
      status: "published",
      operator_roles: [ "creator_generaimpresa" ]
    )

    person = User.create!(
      email_address: "elisa-#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
    @profile = person.create_profile!(display_name: "Elisa Corubolo", username: "elisa_corubolo_#{SecureRandom.hex(3)}")
    @superadmin = User.create!(
      email_address: "profile-superadmin-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      superadmin: true,
      active_role: :superadmin
    )
  end

  test "superadmin sees the person management page" do
    sign_in(@superadmin)

    get admin_profile_url(@profile)

    assert_response :success
    assert_select "h1", "Elisa Corubolo"
    assert_select "form[action='#{admin_profile_role_assignments_path(@profile)}']", count: 1
  end

  test "ordinary user cannot access the person management page" do
    sign_in(@profile.user)

    get admin_profile_url(@profile)

    assert_redirected_to viaggiatori_path
  end

  test "superadmin assigns creator generaimpresa once" do
    sign_in(@superadmin)

    assert_difference -> { @profile.role_assignments.count }, 1 do
      post admin_profile_role_assignments_url(@profile)
    end

    assignment = @profile.role_assignments.last
    assert assignment.operator?
    assert_equal "creator_generaimpresa", assignment.role_operator
    assert_equal @brand, assignment.context
    assert_equal @brand_assignment, assignment.parent

    assert_no_difference -> { @profile.role_assignments.count } do
      post admin_profile_role_assignments_url(@profile)
    end
  end

  test "superadmin revokes an operator role without exposing structural roles" do
    operator = @profile.role_assignments.create!(
      role: :operator,
      role_operator: "creator_generaimpresa",
      context: @brand,
      parent: @brand_assignment
    )
    structural = @profile.role_assignments.create!(role: :ideatore)
    sign_in(@superadmin)

    get admin_profile_url(@profile)
    assert_select "form[action='#{admin_profile_role_assignment_path(@profile, operator)}']", count: 1
    assert_select "form[action='#{admin_profile_role_assignment_path(@profile, structural)}']", count: 0

    assert_difference -> { @profile.role_assignments.count }, -1 do
      delete admin_profile_role_assignment_url(@profile, operator)
    end
    assert structural.reload.persisted?
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
