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
    host! "localhost"
    get new_session_path(site: "posturacorretta")
    assert_difference -> { Session.count }, 1 do
      post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    end
    assert_equal access, @user.sessions.last.brand_access
    assert_redirected_to "/posturacorretta/dashboard"
  end

  test "user without brand access is redirected to the invitation request" do
    host! "localhost"
    get new_session_path(site: "posturacorretta")
    assert_no_difference [-> { BrandAccess.count }, -> { Session.count }] do
      post session_path, params: { site: "posturacorretta", email_address: @user.email_address, password: "password123" }
    end
    assert_redirected_to new_brand_access_request_path(site: "posturacorretta")
  end

  test "existing user accepts a personal invitation while logging in" do
    invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: @user.email_address, invited_by_user: @owner)
    get brand_invitation_path(raw_token)
    assert_difference [-> { BrandAccess.count }, -> { Session.count }], 1 do
      post session_path, params: { invitation: raw_token, email_address: @user.email_address, password: "password123" }
    end
    assert_equal "accepted", invitation.reload.status
    assert_equal @node, @user.sessions.last.brand_access.brand_node
  end

  test "invitation cannot be accepted by another email" do
    _invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: "another@example.com", invited_by_user: @owner)
    get brand_invitation_path(raw_token)
    assert_no_difference [-> { BrandAccess.count }, -> { Session.count }] do
      post session_path, params: { invitation: raw_token, email_address: @user.email_address, password: "password123" }
    end
    assert_redirected_to new_session_path
  end

  test "suspended user cannot create a session" do
    @user.update!(registration_status: "suspended")
    assert_no_difference -> { Session.count } do
      post session_path, params: { email_address: @user.email_address, password: "password123" }
    end
    assert_equal "Questo account è sospeso. Contatta l’amministrazione per verificare l’accesso.", flash[:alert]
  end

  test "brand login rejects external return path" do
    BrandAccess.create!(profile: @user.profile, source_domain: @domain)
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
    post session_path, params: { invitation: token, email_address: @user.email_address, password: "password123" }
    assert_equal "accepted", invitation.reload.status
    assert_equal 2, @user.profile.brand_accesses.active.count
    assert_not_equal first, @user.sessions.last.brand_access
  end
end
