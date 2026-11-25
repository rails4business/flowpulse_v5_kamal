require "test_helper"

class RoleAssignments::ManagerTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "role-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    @root_assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(
      title: "GeneraImpresa",
      slug: "generaimpresa",
      role_assignment: @root_assignment,
      operator_roles: %w[imprenditore_generaimpresa]
    )
    domain = Domain.create!(hostname: "manager-generaimpresa.example", node: @brand, role_assignment: @root_assignment, locale: "it")

    person = User.create!(email_address: "role-person@example.com", password: "password123")
    @profile = person.create_profile!(display_name: "Person")
    @access = BrandAccess.create!(profile: @profile, source_domain: domain)

    @superadmin = User.create!(email_address: "role-superadmin@example.com", password: "password123", superadmin: true)
    @superadmin.create_profile!(display_name: "Superadmin")
  end

  test "assigns a registered role through an active compatible access" do
    assignment = manager.assign_operator!(
      profile: @profile,
      brand_access: @access,
      node: @brand,
      role_code: "creator_generaimpresa"
    )

    assert_equal "imprenditore_generaimpresa", assignment.role_operator
    assert_equal @access, assignment.brand_access
    assert_equal @superadmin.profile, assignment.assigned_by_profile
    assert_equal "active", assignment.status
    assert assignment.starts_at.present?
  end

  test "rejects an assignment without a compatible active access" do
    @access.cancel!

    error = assert_raises(ArgumentError) do
      manager.assign_operator!(
        profile: @profile,
        brand_access: @access,
        node: @brand,
        role_code: "imprenditore_generaimpresa"
      )
    end

    assert_equal "BrandAccess non attivo", error.message
  end

  test "assigns the brand role to a project inside the accessed brand" do
    project = Node.create!(
      title: "Radioestesia e Benessere",
      parent: @brand,
      role_assignment: @root_assignment,
      operator_roles: []
    )

    assignment = manager.assign_operator!(
      profile: @profile,
      brand_access: @access,
      node: project,
      role_code: "imprenditore_generaimpresa"
    )

    assert_equal project, assignment.context
    assert_equal @access, assignment.brand_access
  end

  test "keeps revoked assignments for audit" do
    assignment = manager.assign_operator!(
      profile: @profile,
      brand_access: @access,
      node: @brand,
      role_code: "imprenditore_generaimpresa"
    )

    assert_no_difference -> { RoleAssignment.count } do
      manager.revoke!(assignment)
    end
    assert_equal "revoked", assignment.reload.status
    assert assignment.ends_at.present?
  end

  private

    def manager
      RoleAssignments::Manager.new(actor: @superadmin)
    end
end
