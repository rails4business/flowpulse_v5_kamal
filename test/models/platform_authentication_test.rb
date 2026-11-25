require "test_helper"

class PlatformAuthenticationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "platform-admin@example.com", password: "password123")
    @profile = @user.create_profile!(display_name: "Platform admin")
    @credential = PlatformCredential.create!(
      profile: @profile,
      email_address: @user.email_address,
      password: "platform-password",
      email_verified_at: Time.current
    )
  end

  test "an effective system assignment grants the system superadmin capability" do
    assignment = SystemRoleAssignment.create!(profile: @profile, role_code: "superadmin")

    assert @user.superadmin_user?

    assignment.update!(status: :revoked)
    assert_not @user.superadmin_user?
  end

  test "a platform session belongs to the same profile as its credential" do
    SystemRoleAssignment.create!(profile: @profile, role_code: "superadmin")
    session = @user.sessions.create!(
      profile: @profile,
      platform_credential: @credential,
      authentication_method: "platform_credential"
    )

    assert session.valid?
    assert session.active?
  end

  test "a platform credential cannot be combined with a Brand session" do
    owner = User.create!(email_address: "platform-owner@example.com", password: "password123")
    owner_profile = owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner_profile, role: :ideatore)
    node = Node.create!(title: "Platform test Brand", role_assignment: assignment)
    domain = Domain.create!(hostname: "platform-brand.example", node:, role_assignment: assignment, locale: "it")
    access = BrandAccess.create!(profile: @profile, source_domain: domain)

    session = @user.sessions.new(
      profile: @profile,
      brand_access: access,
      platform_credential: @credential
    )

    assert_not session.valid?
    assert_includes session.errors[:platform_credential_id], "non può essere combinata con credenziali Brand"
  end
end
