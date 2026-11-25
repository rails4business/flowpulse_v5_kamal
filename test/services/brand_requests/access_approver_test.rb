require "test_helper"

class BrandRequests::AccessApproverTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "approver-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(title: "GeneraImpresa", slug: "generaimpresa", role_assignment: @root_assignment, operator_roles: %w[imprenditore_generaimpresa])
    @domain = Domain.create!(hostname: "approver-generaimpresa.example", node: @brand, role_assignment: @root_assignment, locale: "it")
    @entrepreneur = User.create!(email_address: "approver-entrepreneur@example.com", password: "password123")
    @entrepreneur.create_profile!(display_name: "Entrepreneur")
    access = BrandAccess.create!(profile: @entrepreneur.profile, source_domain: @domain)
    @project = Node.create!(title: "Assigned project", parent: @brand, role_assignment: @root_assignment, responsible_profile: @entrepreneur.profile)
    RoleAssignment.create!(profile: @entrepreneur.profile, role: :operator, role_operator: "imprenditore_generaimpresa", context: @project, parent: @root_assignment, brand_access: access)
    person = User.create!(email_address: "approver-person@example.com", password: "password123")
    @profile = person.create_profile!(display_name: "Person")
    @request = BrandRequest.create!(domain: @domain, brand_node: @brand, subject: @project, requester_profile: @profile, title: "Access", kind: "access", audience: "user")
  end

  test "approves access without creating a role" do
    access = BrandRequests::AccessApprover.new(actor: @entrepreneur).approve!(@request)

    assert access.active?
    assert_equal @brand, access.brand_node
    assert_equal "accepted", @request.reload.status
    assert_equal @entrepreneur.profile, @request.assigned_to_profile
    assert_empty @profile.role_assignments
    grant = access.grants.find_by!(node: @project)
    assert_equal @request, grant.brand_request
    assert grant.active?
    assert access.grant_managed?
  end

  test "requires a linked profile" do
    @request.update_column(:requester_profile_id, nil)

    error = assert_raises(ArgumentError) do
      BrandRequests::AccessApprover.new(actor: @entrepreneur).approve!(@request)
    end

    assert_equal "Collega prima la richiesta a un Profile", error.message
    assert_equal "open", @request.reload.status
  end
end
