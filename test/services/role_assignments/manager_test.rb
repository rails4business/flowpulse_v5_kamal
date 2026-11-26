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

  test "superadmin must use an enabled registered role compatible with the brand" do
    %w[unknown_role segreteria insegnante_posturacorretta utente superadmin].each do |code|
      assert_no_difference -> { RoleAssignment.count } do
        assert_raises(ArgumentError) do
          manager.assign_operator!(profile: @profile, brand_access: @access, node: @brand, role_code: code)
        end
      end
    end
  end

  test "repeated assignment is idempotent and preserves author dates and audit" do
    assignment = assign_role
    original = assignment.attributes

    travel 1.minute do
      assert_no_difference -> { RoleAssignment.count } do
        assert_equal assignment, assign_role
      end
    end

    assert_equal original, assignment.reload.attributes
    assert_equal ["assigned"], assignment.audit_log.pluck("event")
    assert_equal @superadmin.profile.id, assignment.audit_log.first.fetch("actor_profile_id")
  end

  test "revocation clears selection and preserves history when the same role is reactivated" do
    assignment = assign_role
    @access.select_role_assignment!(assignment)
    manager.revoke!(assignment)

    assert_nil @access.reload.current_role_assignment
    assert_equal %w[assigned revoked], assignment.reload.audit_log.pluck("event")
    assert_equal @superadmin.profile.id, assignment.audit_log.last.fetch("actor_profile_id")
    snapshot = assignment.attributes
    manager.revoke!(assignment)
    assert_equal snapshot, assignment.reload.attributes

    assert_equal assignment, assign_role
    assert_equal %w[assigned revoked reactivated], assignment.reload.audit_log.pluck("event")
    assert_nil assignment.ends_at
  end

  test "superadmin can revoke a historical assignment after the brand access was cancelled" do
    assignment = assign_role
    @access.cancel!

    manager.revoke!(assignment)

    assert_equal "revoked", assignment.reload.status
    assert_equal %w[assigned revoked], assignment.audit_log.pluck("event")
    assert_equal "cancelled", @access.reload.status
  end

  test "assigning across a nested brand boundary is invalid even for the superadmin" do
    nested = Node.create!(title: "Nested Brand", parent: @brand, role_assignment: @root_assignment)
    Domain.create!(hostname: "nested-role-manager.example", node: nested, role_assignment: @root_assignment)

    assert_no_difference -> { RoleAssignment.count } do
      assert_raises(ArgumentError) do
        manager.assign_operator!(profile: @profile, brand_access: @access, node: nested, role_code: "imprenditore_generaimpresa")
      end
    end
  end

  test "a stale access is rechecked before assignment" do
    stale_access = BrandAccess.find(@access.id)
    @access.cancel!

    assert_no_difference -> { RoleAssignment.count } do
      assert_raises(ArgumentError) do
        manager.assign_operator!(profile: @profile, brand_access: stale_access, node: @brand, role_code: "imprenditore_generaimpresa")
      end
    end
  end

  test "structural roles cannot be revoked through the operational role manager" do
    assert_no_difference -> { RoleAssignment.count } do
      assert_raises(ArgumentError) { manager.revoke!(@root_assignment) }
    end
    assert_equal "active", @root_assignment.reload.status
    assert_empty @root_assignment.audit_log
  end

  test "assignment failure does not leave an audit event or a partial assignment" do
    child_role = RoleAssignment.create!(profile: @profile, role: :creator, parent: @root_assignment)
    @brand.update_column(:role_assignment_id, child_role.id)

    assert_no_difference -> { RoleAssignment.count } do
      assert_raises(ActiveRecord::RecordInvalid) { assign_role }
    end

    assert_empty RoleAssignment.operator.where(profile: @profile)
    assert_empty @access.reload.role_assignments
  end

  test "a legacy superadmin without a profile keeps access and receives an audit identity" do
    legacy = User.create!(email_address: "legacy-audit-superadmin@example.com", password: "password123", superadmin: true)

    assert_difference -> { Profile.count }, 1 do
      assignment = RoleAssignments::Manager.new(actor: legacy).assign_operator!(
        profile: @profile, brand_access: @access, node: @brand, role_code: "imprenditore_generaimpresa"
      )
      assert_equal legacy.reload.profile, assignment.assigned_by_profile
      assert_equal legacy.profile.id, assignment.audit_log.first.fetch("actor_profile_id")
    end
  end

  private

    def manager
      RoleAssignments::Manager.new(actor: @superadmin)
    end

    def assign_role
      manager.assign_operator!(profile: @profile, brand_access: @access, node: @brand, role_code: "imprenditore_generaimpresa")
    end
end
