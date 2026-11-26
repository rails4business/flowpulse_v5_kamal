require "test_helper"

class Brands::GeneraImpresaPeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "people-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(title: "GeneraImpresa", slug: "generaimpresa", role_assignment: assignment, operator_roles: %w[imprenditore_generaimpresa])
    @domain = Domain.create!(hostname: "people-generaimpresa.example", node: @brand, role_assignment: assignment, locale: "it")
    @entrepreneur = User.create!(email_address: "people-entrepreneur@example.com", password: "password123")
    @entrepreneur.create_profile!(display_name: "Entrepreneur")
    entrepreneur_access = BrandAccess.create!(profile: @entrepreneur.profile, source_domain: @domain)
    @project = Node.create!(title: "My project", parent: @brand, role_assignment: assignment, responsible_profile: @entrepreneur.profile)
    @outside = Node.create!(title: "Outside", parent: @brand, role_assignment: assignment)
    RoleAssignment.create!(profile: @entrepreneur.profile, role: :operator, role_operator: "imprenditore_generaimpresa", context: @project, parent: assignment, brand_access: entrepreneur_access)
    person = User.create!(email_address: "people-person@example.com", password: "password123")
    @profile = person.create_profile!(display_name: "Project person")
    request = BrandRequest.create!(domain: @domain, brand_node: @brand, subject: @project, requester_profile: @profile, title: "Access", kind: "access", audience: "user")
    superadmin = User.create!(email_address: "people-superadmin@example.com", password: "password123", superadmin: true)
    superadmin.create_profile!(display_name: "Superadmin")
    @access = BrandRequests::AccessApprover.new(actor: superadmin).approve!(request)
    @grant = @access.grants.find_by!(node: @project)
  end

  test "shows people admitted through project requests" do
    sign_in(@entrepreneur)

    get genera_impresa_project_people_url(@project)

    assert_response :success
    assert_select "[data-brand-access-grant-id='#{@grant.id}']", text: /Project person/
  end

  test "revokes the scoped grant and managed access" do
    sign_in(@entrepreneur)

    delete genera_impresa_project_person_url(@project, @grant)

    assert_redirected_to genera_impresa_project_people_path(@project)
    assert_equal "revoked", @grant.reload.status
    assert_equal "cancelled", @access.reload.status
  end

  test "cannot open people from another project" do
    sign_in(@entrepreneur)

    get genera_impresa_project_people_url(@outside)

    assert_response :not_found
  end

  private

    def sign_in(user)
      host! @domain.hostname
      access = user.profile.brand_accesses.find_by!(brand_node: @brand)
      access.create_brand_credential!(brand_node: @brand, email_address: user.email_address, password: "password123") unless access.brand_credential
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
