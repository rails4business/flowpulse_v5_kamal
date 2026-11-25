require "test_helper"

class BrandCredentialTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "credential-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner.profile, role: :ideatore)
    @brand = Node.create!(title: "Credential Brand", slug: "credential-brand", role_assignment: assignment)
    @domain = Domain.create!(hostname: "credential-brand.example", node: @brand, role_assignment: assignment, locale: "it")
    @user = User.create!(email_address: "credential-user@example.com", password: "global-password")
    @profile = @user.create_profile!(display_name: "Credential user")
    @access = BrandAccess.create!(profile: @profile, source_domain: @domain)
  end

  test "authenticates with a password specific to the brand" do
    credential = BrandCredential.create!(
      brand_access: @access,
      brand_node: @brand,
      email_address: "credential-user@example.com",
      password: "brand-password",
      password_confirmation: "brand-password"
    )

    assert credential.authenticate("brand-password")
    assert_not credential.authenticate("global-password")
  end

  test "allows the same email in different brands but not twice in one brand" do
    BrandCredential.create!(
      brand_access: @access,
      brand_node: @brand,
      email_address: @user.email_address,
      password: "brand-password"
    )
    other_user = User.create!(email_address: "other-credential-user@example.com", password: "password123")
    other_profile = other_user.create_profile!(display_name: "Other")
    duplicate_access = BrandAccess.create!(
      profile: other_profile,
      source_domain: @domain,
      brand_node: @brand
    )
    duplicate = BrandCredential.new(
      brand_access: duplicate_access,
      brand_node: @brand,
      email_address: @user.email_address,
      password: "another-password"
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:email_address].present?
  end

  test "rejects a brand different from its access" do
    other_brand = Node.create!(title: "Other Brand", slug: "other-credential-brand", role_assignment: @brand.role_assignment)
    credential = BrandCredential.new(
      brand_access: @access,
      brand_node: other_brand,
      email_address: @user.email_address,
      password: "brand-password"
    )

    assert_not credential.valid?
    assert_includes credential.errors[:brand_node], "deve corrispondere al BrandAccess"
  end

  test "a pending verification credential cannot open a Brand session" do
    credential = BrandCredential.create!(
      brand_access: @access,
      brand_node: @brand,
      email_address: @user.email_address,
      password: "brand-password",
      status: "pending_verification"
    )

    assert_not credential.active?
    assert_not_includes BrandCredential.active, credential
  end
end
