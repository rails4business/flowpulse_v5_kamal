require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "traveler@example.com", password: "password123")
    @user.create_profile!(display_name: "Traveler")
    @owner = User.create!(email_address: "owner@example.com", password: "password123")
    owner_profile = @owner.create_profile!(display_name: "Owner")
    @assignment = RoleAssignment.create!(profile: owner_profile, role: :creator_of_worlds)
    @node = Node.create!(title: "PosturaCorretta", role_assignment: @assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "posturacorretta.org", node: @node, role_assignment: @assignment, locale: "it", auth_slug: "posturacorretta", auth_enabled: true, auth_default_path: "/posturacorretta/dashboard", site_title: "PosturaCorretta")
  end

  test "existing brand member logs in without a new invitation" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    credential = create_credential(access)
    host! "localhost"
    get new_session_path(site: "posturacorretta")
    assert_difference -> { Session.count }, 1 do
      post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    end
    assert_equal access, @user.sessions.last.brand_access
    assert_equal credential, @user.sessions.last.brand_credential
    assert_redirected_to "/posturacorretta/dashboard"
  end

  test "user without a Brand credential cannot create a session" do
    host! "localhost"
    get new_session_path(site: "posturacorretta")
    assert_no_difference [-> { BrandAccess.count }, -> { Session.count }] do
      post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    end
    assert_redirected_to new_session_path(site: "posturacorretta")
    assert_equal "Email o password non valide per questo Brand.", flash[:alert]
  end

  test "ordinary user keeps the legacy login outside a Brand during the migration" do
    assert_no_difference -> { BrandAccess.count } do
      assert_difference -> { Session.count }, 1 do
        post session_path, params: { email_address: @user.email_address, password: "password123" }
      end
    end

    assert_equal "legacy_user_password", @user.sessions.last.authentication_method
    assert_nil @user.sessions.last.brand_access
    assert_nil @user.sessions.last.brand_credential
  end

  test "system superadmin logs in with the PlatformCredential without the legacy flag" do
    platform_user = User.create!(email_address: "system-admin@example.com", password: "legacy-password")
    profile = platform_user.create_profile!(display_name: "System admin")
    credential = PlatformCredential.create!(
      profile:,
      email_address: platform_user.email_address,
      password: "platform-password"
    )
    SystemRoleAssignment.create!(profile:, role_code: "superadmin")

    post session_path, params: {
      email_address: platform_user.email_address,
      password: "platform-password"
    }

    authenticated_session = platform_user.sessions.last
    assert_redirected_to root_path
    assert_equal profile, authenticated_session.profile
    assert_equal credential, authenticated_session.platform_credential
    assert_equal "platform_credential", authenticated_session.authentication_method
  end

  test "existing user accepts a personal invitation while logging in" do
    invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: @user.email_address, invited_by_user: @owner)
    get brand_invitation_path(raw_token)
    assert_difference [-> { BrandAccess.count }, -> { BrandCredential.count }, -> { Session.count }], 1 do
      post users_path, params: { invitation: raw_token, user: { email_address: @user.email_address, password: "brand-password", password_confirmation: "brand-password" } }
    end
    assert_equal "accepted", invitation.reload.status
    assert_equal @node, @user.sessions.last.brand_access.brand_node
  end

  test "accepting an invitation while logging in links the access request to the profile" do
    contact = @owner.profile.impegno_contacts.create!(name: "Traveler", email: @user.email_address)
    access_request = BrandRequest.create!(
      domain: @domain, brand_node: @node, subject: @node, participant_contact: contact,
      title: "Richiesta accesso", kind: "access", status: "invited"
    )
    _invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: @user.email_address, invited_by_user: @owner, brand_request: access_request)
    get brand_invitation_path(raw_token)
    post users_path, params: { invitation: raw_token, user: { email_address: @user.email_address, password: "brand-password", password_confirmation: "brand-password" } }

    assert_equal "accepted", access_request.reload.status
    assert_equal @user.profile, access_request.requester_profile
  end

  test "invitation credential cannot be configured with another email" do
    _invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: "another@example.com", invited_by_user: @owner)
    get brand_invitation_path(raw_token)
    assert_no_difference [-> { BrandAccess.count }, -> { BrandCredential.count }, -> { Session.count }] do
      post users_path, params: { invitation: raw_token, user: { email_address: @user.email_address, password: "brand-password", password_confirmation: "brand-password" } }
    end
    assert_response :unprocessable_entity
  end

  test "suspended user cannot create a session" do
    @user.update!(registration_status: "suspended")
    assert_no_difference -> { Session.count } do
      post session_path, params: { email_address: @user.email_address, password: "password123" }
    end
    assert_equal "Email o password non valide.", flash[:alert]
  end

  test "brand login rejects external return path" do
    access = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    create_credential(access)
    host! "localhost"
    get new_session_path(site: "posturacorretta", return_to: "https://evil.example")
    post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    assert_redirected_to "/posturacorretta/dashboard"
  end

  test "same user keeps distinct accesses for two invited brands" do
    first = BrandAccess.create!(profile: @user.profile, source_domain: @domain)
    second_node = Node.create!(title: "Second Brand", role_assignment: @assignment, status: "published", visibility: "public")
    second_domain = Domain.create!(hostname: "second.example", node: second_node, role_assignment: @assignment, locale: "it")
    invitation, token = BrandInvitation.issue!(brand_node: second_node, source_domain: second_domain, email_address: @user.email_address, invited_by_user: @owner)
    get brand_invitation_path(token)
    post users_path, params: { invitation: token, user: { email_address: @user.email_address, password: "second-brand-password", password_confirmation: "second-brand-password" } }
    assert_equal "accepted", invitation.reload.status
    assert_equal 2, @user.profile.brand_accesses.active.count
    assert_not_equal first, @user.sessions.last.brand_access
  end

  private

    def create_credential(access, password: "password123")
      BrandCredential.create!(
        brand_access: access,
        brand_node: access.brand_node,
        email_address: access.profile.user.email_address,
        password: password
      )
    end
end
