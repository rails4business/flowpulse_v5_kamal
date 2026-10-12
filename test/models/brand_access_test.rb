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
    @node = Node.create!(title: "Accessible Brand", role_assignment: @assignment, status: "published", visibility: "public")
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
end
