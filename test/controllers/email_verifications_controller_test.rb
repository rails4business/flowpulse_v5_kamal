require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "verification-owner@example.com", password: "password123")
    owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Verified Brand", role_assignment: assignment, status: "published", visibility: "public")
    @domain = Domain.create!(
      hostname: "verified.example",
      node: @node,
      role_assignment: assignment,
      locale: "it",
      auth_slug: "verified",
      auth_enabled: true,
      auth_default_path: "/verified",
      site_title: "Verified"
    )
    @user = User.create!(
      email_address: "pending-verification@example.com",
      password: "password123",
      registration_status: "pending_email_verification",
      email_verified_at: nil
    )
    @user.create_profile!(display_name: "Pending")
    @verification, @raw_token = EmailVerification.issue!(
      user: @user,
      brand_node: @node,
      requested_domain: @domain,
      return_to: "/verified"
    )
  end

  test "confirmation activates user, brand access and session" do
    host! "verified.example"

    get email_verification_path(@raw_token)
    assert_response :success

    assert_difference -> { Session.count }, 1 do
      assert_difference -> { BrandAccess.count }, 1 do
        patch email_verification_path(@raw_token)
      end
    end

    assert_redirected_to "/verified"
    assert @user.reload.email_verified?
    assert @user.active_registration?
    assert @verification.reload.verified_at.present?
    assert_equal @node, @user.sessions.order(:created_at).last.brand_access.brand_node
  end

  test "a verification is single use" do
    host! "verified.example"
    patch email_verification_path(@raw_token)
    patch email_verification_path(@raw_token)

    assert_redirected_to new_user_path
  end
end
