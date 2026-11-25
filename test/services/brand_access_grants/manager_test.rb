require "test_helper"

class BrandAccessGrants::ManagerTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "grant-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(title: "GeneraImpresa", slug: "generaimpresa", role_assignment: assignment, operator_roles: %w[imprenditore_generaimpresa])
    domain = Domain.create!(hostname: "grant-generaimpresa.example", node: @brand, role_assignment: assignment, locale: "it")
    @entrepreneur = User.create!(email_address: "grant-entrepreneur@example.com", password: "password123")
    @entrepreneur.create_profile!(display_name: "Entrepreneur")
    entrepreneur_access = BrandAccess.create!(profile: @entrepreneur.profile, source_domain: domain)
    @project = Node.create!(title: "Project", parent: @brand, role_assignment: assignment, responsible_profile: @entrepreneur.profile)
    @child = Node.create!(title: "Child", parent: @project, role_assignment: assignment, responsible_profile: @entrepreneur.profile)
    RoleAssignment.create!(profile: @entrepreneur.profile, role: :operator, role_operator: "imprenditore_generaimpresa", context: @project, parent: assignment, brand_access: entrepreneur_access)
    person = User.create!(email_address: "grant-person@example.com", password: "password123")
    @profile = person.create_profile!(display_name: "Person")
    @access = BrandAccess.create!(profile: @profile, source_domain: domain, grant_managed: true)
  end

  test "keeps the brand access active while another project grant remains" do
    manager = BrandAccessGrants::Manager.new(actor: @entrepreneur)
    first = manager.grant!(brand_access: @access, node: @project)
    second = manager.grant!(brand_access: @access, node: @child)

    manager.revoke!(first)

    assert_equal "revoked", first.reload.status
    assert second.reload.active?
    assert @access.reload.active?
  end

  test "cancels a managed brand access after its last grant is revoked" do
    manager = BrandAccessGrants::Manager.new(actor: @entrepreneur)
    grant = manager.grant!(brand_access: @access, node: @project)

    manager.revoke!(grant)

    assert_equal "revoked", grant.reload.status
    assert_equal "cancelled", @access.reload.status
  end

  test "does not cancel a legacy global access" do
    @access.update!(grant_managed: false)
    manager = BrandAccessGrants::Manager.new(actor: @entrepreneur)
    grant = manager.grant!(brand_access: @access, node: @project)

    manager.revoke!(grant)

    assert @access.reload.active?
  end
end
