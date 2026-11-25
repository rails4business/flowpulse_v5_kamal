require "test_helper"

class Brands::GeneraImpresaProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "projects-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(title: "GeneraImpresa", slug: "generaimpresa", role_assignment: @root_assignment, operator_roles: %w[imprenditore_generaimpresa])
    domain = Domain.create!(hostname: "projects-generaimpresa.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @user = User.create!(email_address: "projects-entrepreneur@example.com", password: "password123")
    @user.create_profile!(display_name: "Entrepreneur")
    access = BrandAccess.create!(profile: @user.profile, source_domain: domain)
    @project = Node.create!(title: "My project", parent: @brand, role_assignment: @root_assignment, responsible_profile: @user.profile)
    RoleAssignment.create!(profile: @user.profile, role: :operator, role_operator: "imprenditore_generaimpresa", context: @project, parent: @root_assignment, brand_access: access)
    @outside = Node.create!(title: "Other project", parent: @brand, role_assignment: @root_assignment)
  end

  test "shows only nodes assigned to the entrepreneur" do
    sign_in(@user)

    get genera_impresa_my_projects_url

    assert_response :success
    assert_select "[data-managed-node-id='#{@project.id}']", count: 1
    assert_select "[data-managed-node-id='#{@outside.id}']", count: 0
    assert_select "body", text: /1\/7/
  end

  test "creates a child inside the assigned project" do
    sign_in(@user)

    assert_difference -> { @user.profile.responsible_nodes.count }, 1 do
      post genera_impresa_my_projects_url, params: {
        parent_id: @project.id,
        node: { title: "New activity", description: "Description", status: "draft", visibility: "private" }
      }
    end

    node = @user.profile.responsible_nodes.order(:id).last
    assert_equal @project, node.parent
    assert_equal "private", node.visibility
  end

  test "cannot update a project outside the assigned perimeter" do
    sign_in(@user)

    patch genera_impresa_my_project_url(@outside), params: { node: { title: "Stolen" } }

    assert_response :not_found
    assert_equal "Other project", @outside.reload.title
  end

  test "requires authentication" do
    get genera_impresa_my_projects_url

    assert_redirected_to new_session_path(return_to: genera_impresa_my_projects_path)
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
