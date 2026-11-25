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
      operator_roles: %w[gestore_generaimpresa imprenditore_generaimpresa]
    )
    @domain = Domain.create!(hostname: "generaimpresa-#{SecureRandom.hex(3)}.example", node: @brand, role_assignment: @brand_assignment, locale: "it")
    @project = Node.create!(title: "Radioestesia e Benessere", slug: "radioestesiaebenessere", parent: @brand, role_assignment: @brand_assignment, operator_roles: %w[legacy_collaborator])

    person = User.create!(
      email_address: "elisa-#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
    @profile = person.create_profile!(display_name: "Elisa Corubolo", username: "elisa_corubolo_#{SecureRandom.hex(3)}")
    @brand_access = BrandAccess.create!(profile: @profile, source_domain: @domain)
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
    assert_select "form[action='#{admin_profile_role_assignments_path(@profile)}']", count: 2
    assert_select "a[href='#{admin_profile_brand_accesses_path(@profile)}']", text: /BrandAccess/
    assert_select "a[href='#{admin_profile_nodes_path(@profile)}']", text: /Node/
  end

  test "superadmin sees the global Profile index" do
    sign_in(@superadmin)

    get admin_profiles_url

    assert_response :success
    assert_select "h1", "Persone e Profile"
    assert_select "a[href='#{admin_profile_path(@profile)}']", text: "Apri scheda"
    assert_select "tbody", text: /Elisa Corubolo/
  end

  test "ordinary user cannot access the global Profile index" do
    sign_in(@profile.user)

    get admin_profiles_url

    assert_redirected_to viaggiatori_path
  end

  test "superadmin sees every assigned role with access and status" do
    operator = @profile.role_assignments.create!(
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: @brand,
      parent: @brand_assignment,
      brand_access: @brand_access,
      status: "active"
    )
    structural = @profile.role_assignments.create!(role: :ideatore)
    sign_in(@superadmin)

    get admin_profile_url(@profile)

    assert_response :success
    assert_select "[data-role-assignment-id='#{operator.id}']", text: /Imprenditore GeneraImpresa/
    assert_select "[data-role-assignment-id='#{operator.id}']", text: /BrandAccess ##{@brand_access.id}/
    assert_select "[data-role-assignment-id='#{structural.id}']", text: /Ideatore/
  end

  test "ordinary user cannot access the person management page" do
    sign_in(@profile.user)

    get admin_profile_url(@profile)

    assert_redirected_to viaggiatori_path
  end

  test "superadmin assigns imprenditore generaimpresa once" do
    sign_in(@superadmin)

    assert_difference -> { @profile.role_assignments.count }, 1 do
      post admin_profile_role_assignments_url(@profile), params: { role_code: "imprenditore_generaimpresa" }
    end

    assignment = @profile.role_assignments.last
    assert assignment.operator?
    assert_equal "imprenditore_generaimpresa", assignment.role_operator
    assert_equal @brand, assignment.context
    assert_equal @brand_assignment, assignment.parent
    assert_equal @brand_access, assignment.brand_access
    assert_equal "active", assignment.status

    assert_no_difference -> { @profile.role_assignments.count } do
      post admin_profile_role_assignments_url(@profile), params: { role_code: "imprenditore_generaimpresa" }
    end
  end

  test "superadmin assigns the GeneraImpresa manager role" do
    sign_in(@superadmin)

    assert_difference -> { @profile.role_assignments.count }, 1 do
      post admin_profile_role_assignments_url(@profile), params: { role_code: "gestore_generaimpresa" }
    end

    assignment = @profile.role_assignments.last
    assert_equal "gestore_generaimpresa", assignment.role_operator
    assert_equal @brand_access, assignment.brand_access
    assert_equal @brand, assignment.context
  end

  test "superadmin revokes an operator role without exposing structural roles" do
    operator = @profile.role_assignments.create!(
      role: :operator,
      role_operator: "imprenditore_generaimpresa",
      context: @brand,
      parent: @brand_assignment,
      brand_access: @brand_access
    )
    structural = @profile.role_assignments.create!(role: :ideatore)
    sign_in(@superadmin)

    get admin_profile_url(@profile)
    assert_select "form[action='#{admin_profile_role_assignment_path(@profile, operator)}']", count: 1
    assert_select "form[action='#{admin_profile_role_assignment_path(@profile, structural)}']", count: 0

    assert_no_difference -> { @profile.role_assignments.count } do
      delete admin_profile_role_assignment_url(@profile, operator)
    end
    assert_equal "revoked", operator.reload.status
    assert operator.ends_at.present?
    assert structural.reload.persisted?
  end

  test "superadmin cannot assign the role without a brand access" do
    @brand_access.destroy!
    sign_in(@superadmin)

    assert_no_difference -> { @profile.role_assignments.count } do
      post admin_profile_role_assignments_url(@profile), params: { role_code: "imprenditore_generaimpresa" }
    end

    assert_redirected_to admin_profile_path(@profile)
    assert_equal "Prima di assegnare il ruolo serve un accesso attivo a GeneraImpresa.", flash[:alert]
  end

  test "superadmin revokes and reactivates a brand access" do
    sign_in(@superadmin)

    get admin_profile_brand_accesses_url(@profile)
    assert_response :success
    assert_select "[data-brand-access-id='#{@brand_access.id}'] a[href='#{admin_profile_brand_access_path(@profile, @brand_access)}']", text: @brand.title

    get admin_profile_brand_access_url(@profile, @brand_access)
    assert_response :success
    assert_select "nav", text: /#{Regexp.escape(@profile.display_name)}.*BrandAccess.*#{Regexp.escape(@brand.title)}/m

    delete admin_profile_brand_access_url(@profile, @brand_access)
    assert_redirected_to admin_profile_brand_accesses_path(@profile)
    assert_equal "cancelled", @brand_access.reload.status

    assert_no_difference -> { @profile.brand_accesses.count } do
      post admin_profile_brand_accesses_url(@profile), params: { domain_id: @domain.id }
    end
    assert_equal "active", @brand_access.reload.status
  end

  test "superadmin assigns and removes responsibility for a project" do
    sign_in(@superadmin)

    post admin_profile_node_responsibilities_url(@profile), params: {
      node_id: @project.id,
      role_code: "imprenditore_generaimpresa"
    }

    assert_redirected_to admin_profile_nodes_path(@profile)
    assert_equal @profile, @project.reload.responsible_profile
    assignment = @profile.role_assignments.find_by!(context: @project, role_operator: "imprenditore_generaimpresa")
    assert_equal @brand_access, assignment.brand_access
    assert_equal "active", assignment.status

    collaborator = User.create!(email_address: "project-collaborator@example.com", password: "password123")
    collaborator_profile = collaborator.create_profile!(display_name: "Collaboratore")
    collaborator_assignment = RoleAssignment.create!(
      profile: collaborator_profile,
      role: :operator,
      role_operator: "legacy_collaborator",
      context: @project,
      parent: @brand_assignment
    )

    delete admin_profile_node_responsibility_url(@profile, @project)
    assert_nil @project.reload.responsible_profile
    assert_equal "revoked", assignment.reload.status
    assert_equal "active", collaborator_assignment.reload.status
  end

  test "superadmin opens the profile node index and show with breadcrumbs" do
    @project.update!(responsible_profile: @profile)
    sign_in(@superadmin)

    get admin_profile_nodes_url(@profile)
    assert_response :success
    assert_select "[data-profile-node-id='#{@project.id}'] a[href='#{admin_profile_node_path(@profile, @project)}']", text: @project.title

    get admin_profile_node_url(@profile, @project)
    assert_response :success
    assert_select "nav", text: /#{Regexp.escape(@profile.display_name)}.*Node.*#{Regexp.escape(@project.title)}/m
  end

  test "assigning a project to a new profile transfers responsibility and revokes the old assignment" do
    old_assignment = RoleAssignments::Manager.new(actor: @superadmin).assign_operator!(
      profile: @profile,
      brand_access: @brand_access,
      node: @project,
      role_code: "imprenditore_generaimpresa"
    )
    @project.update!(responsible_profile: @profile)

    new_user = User.create!(email_address: "new-responsible@example.com", password: "password123")
    new_profile = new_user.create_profile!(display_name: "Nuovo responsabile")
    new_access = BrandAccess.create!(profile: new_profile, source_domain: @domain)
    sign_in(@superadmin)

    post admin_profile_node_responsibilities_url(new_profile), params: {
      node_id: @project.id,
      role_code: "imprenditore_generaimpresa"
    }

    assert_equal new_profile, @project.reload.responsible_profile
    assert_equal "revoked", old_assignment.reload.status
    assert_equal "active", new_profile.role_assignments.find_by!(context: @project).status
    assert_equal new_access, new_profile.role_assignments.find_by!(context: @project).brand_access
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
