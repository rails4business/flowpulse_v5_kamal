require "test_helper"

class BrandAccessTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "brand-access@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @user.create_profile!(display_name: "Traveler")
    creator = User.create!(
      email_address: "brand-access-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    creator.create_profile!(display_name: "Creator")
    @assignment = RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Accessible Brand", slug: "posturacorretta", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "accessible.example", node: @node, role_assignment: @assignment, locale: "it")
  end

  test "syncs the brand node from the source domain" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)

    assert_equal @node, access.brand_node
    assert_equal "active", access.status
    assert access.joined_at.present?
  end

  test "does not allow source domains without a node" do
    domain = Domain.create!(hostname: "without-node.example", role_assignment: @assignment, locale: "it")
    access = BrandAccess.new(profile: @user.profile, source_domain: domain)

    assert_not access.valid?
    assert_includes access.errors[:source_domain_id], "deve essere collegato a un nodo"
  end

  test "allows only one access per profile and brand node" do
    BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    translated_domain = Domain.create!(hostname: "accessible-en.example", node: @node, role_assignment: @assignment, locale: "en")
    duplicate = BrandAccess.new(profile: @user.profile, source_domain: translated_domain)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:brand_node_id], "ha già un accesso per questo brand"
  end

  test "accepts only a current role assignment belonging to the same access" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    assignment = RoleAssignment.create!(
      profile: @user.profile,
      role: :operator,
      role_operator: "insegnante_posturacorretta",
      context: @node,
      parent: @assignment,
      brand_access: access
    )

    access.select_role_assignment!(assignment)

    assert_equal assignment, access.reload.current_role_assignment
  end

  test "rejects a current role assignment belonging to another access" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    other_user = User.create!(email_address: "other-access@example.com", password: "password123")
    other_profile = other_user.create_profile!(display_name: "Other")
    other_access = BrandAccess.create!(profile: other_profile, source_domain: @domain)
    other_assignment = RoleAssignment.create!(
      profile: other_profile,
      role: :operator,
      role_operator: "insegnante_posturacorretta",
      context: @node,
      parent: @assignment,
      brand_access: other_access
    )

    access.current_role_assignment = other_assignment

    assert_not access.valid?
    assert_includes access.errors[:current_role_assignment], "deve appartenere a questo accesso al Brand"
  end

  test "clears the current role assignment when the access is cancelled" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    assignment = RoleAssignment.create!(
      profile: @user.profile,
      role: :operator,
      role_operator: "insegnante_posturacorretta",
      context: @node,
      parent: @assignment,
      brand_access: access
    )
    access.select_role_assignment!(assignment)

    access.cancel!

    assert_nil access.reload.current_role_assignment
  end

  test "selection rejects an assignment that expired after it was loaded" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    assignment = RoleAssignment.create!(profile: @user.profile, role: :operator,
      role_operator: "insegnante_posturacorretta", context: @node, parent: @assignment, brand_access: access)
    RoleAssignment.where(id: assignment.id).update_all(ends_at: 1.minute.ago)

    assert_raises(ActiveRecord::RecordInvalid) { access.select_role_assignment!(assignment) }
    assert_nil access.reload.current_role_assignment
  end

  test "updating an access clears a stale selection without blocking the update" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    assignment = RoleAssignment.create!(profile: @user.profile, role: :operator,
      role_operator: "insegnante_posturacorretta", context: @node, parent: @assignment, brand_access: access)
    access.select_role_assignment!(assignment)
    assignment.update!(ends_at: 1.minute.ago)

    access.reload.update!(joined_at: Time.current)

    assert_nil access.reload.current_role_assignment
    assert access.active?
  end
end
