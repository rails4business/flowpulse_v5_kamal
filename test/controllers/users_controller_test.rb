require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "localhost"
    @owner = User.create!(email_address: "registration-owner@example.com", password: "password123")
    owner_profile = @owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner_profile, role: :creator_of_worlds)
    @node = Node.create!(title: "PosturaCorretta", role_assignment: assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "posturacorretta.org", node: @node, role_assignment: assignment, locale: "it", auth_slug: "posturacorretta", auth_enabled: true, auth_default_path: "/posturacorretta/dashboard", site_title: "PosturaCorretta")
  end

  test "registration page requires a personal invitation" do
    host! "localhost"
    get new_user_path(site: "posturacorretta")
    assert_redirected_to new_brand_access_request_path(site: "posturacorretta")
  end

  test "direct registration without invitation creates nothing" do
    assert_no_difference [-> { User.count }, -> { Profile.count }, -> { BrandAccess.count }, -> { EmailVerification.count }] do
      post users_path, params: { site: "posturacorretta", user: { email_address: "no-invite@example.com", password: "password123", password_confirmation: "password123" } }
    end
    assert_response :unprocessable_entity
    assert_select "li", text: /serve un invito personale valido/
  end

  test "invited person creates active account profile access and session without email delivery" do
    contact = @owner.profile.impegno_contacts.create!(name: "Invited New", email: "invited-new@example.com")
    access_request = BrandRequest.create!(
      domain: @domain, brand_node: @node, subject: @node, participant_contact: contact,
      title: "Richiesta accesso", kind: "access", status: "invited"
    )
    invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: "invited-new@example.com", invited_by_user: @owner, brand_request: access_request)
    get brand_invitation_path(raw_token)

    assert_no_emails do
      assert_difference [-> { User.count }, -> { Profile.count }, -> { BrandAccess.count }, -> { BrandCredential.count }, -> { Session.count }], 1 do
        assert_no_difference -> { EmailVerification.count } do
          post users_path, params: { invitation: raw_token, user: { email_address: "invited-new@example.com", password: "password123", password_confirmation: "password123" } }
        end
      end
    end

    user = User.find_by!(email_address: "invited-new@example.com")
    assert user.active_registration?
    assert_not user.email_verified?
    assert_equal "accepted", invitation.reload.status
    access = user.profile.brand_accesses.active.first
    assert_equal @node, access.brand_node
    assert access.brand_credential.authenticate("password123")
    assert_not user.authenticate("password123")
    assert_equal "brand_invitation", user.sessions.last.authentication_method
    assert_equal access.brand_credential, user.sessions.last.brand_credential
    assert_equal "accepted", access_request.reload.status
    assert access_request.resolved_at.present?
    assert_equal user.profile, access_request.requester_profile
    assert_equal contact, access_request.participant_contact
    assert_redirected_to "/posturacorretta/dashboard"
  end


  test "existing global user creates a separate credential for the invited brand" do
    existing = User.create!(email_address: "existing-global@example.com", password: "global-password")
    existing.create_profile!(display_name: "Existing global")
    invitation, raw_token = BrandInvitation.issue!(
      brand_node: @node,
      source_domain: @domain,
      email_address: existing.email_address,
      invited_by_user: @owner
    )
    get brand_invitation_path(raw_token)

    assert_no_difference [-> { User.count }, -> { Profile.count }, -> { RoleAssignment.count }] do
      assert_difference [-> { BrandAccess.count }, -> { BrandCredential.count }, -> { Session.count }], 1 do
        post users_path, params: {
          invitation: raw_token,
          user: {
            email_address: existing.email_address,
            password: "brand-password",
            password_confirmation: "brand-password"
          }
        }
      end
    end

    credential = existing.profile.brand_accesses.find_by!(brand_node: @node).brand_credential
    assert credential.authenticate("brand-password")
    assert existing.authenticate("global-password")
    assert_equal "accepted", invitation.reload.status
  end

  test "invitation email cannot be replaced during registration" do
    _invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: "right-person@example.com", invited_by_user: @owner)
    get brand_invitation_path(raw_token)
    assert_no_difference -> { User.count } do
      post users_path, params: { invitation: raw_token, user: { email_address: "wrong-person@example.com", password: "password123", password_confirmation: "password123" } }
    end
    assert_response :unprocessable_entity
    assert_select "li", text: /indirizzo invitato/
  end

  test "registration rejects an invitation submitted on another brand host" do
    invitation, token = invite("wrong-host@example.com")
    other = Node.create!(title: "Other Brand", role_assignment: @node.role_assignment)
    domain = Domain.create!(hostname: "other-registration.example", node: other, role_assignment: @node.role_assignment)
    host! domain.hostname

    assert_no_difference [-> { User.count }, -> { Profile.count }, -> { BrandAccess.count }, -> { Session.count }] do
      post users_path, params: { invitation: token, user: registration_attributes(invitation.email_address) }
    end

    assert_redirected_to new_brand_access_request_path
    assert invitation.reload.pending?
  end

  test "an expired explicit invitation does not fall back to a previously remembered invitation" do
    remembered, remembered_token = invite("remembered@example.com")
    expired, expired_token = invite("expired@example.com")
    expired.update!(expires_at: 1.minute.ago)
    get brand_invitation_path(remembered_token)

    assert_no_difference [-> { User.count }, -> { BrandAccess.count }, -> { Session.count }] do
      post users_path, params: { invitation: expired_token, user: registration_attributes(remembered.email_address) }
    end

    assert_redirected_to new_brand_access_request_path(site: "posturacorretta")
    assert remembered.reload.pending?
  end

  test "failed password confirmation leaves no partial registration and allows a retry" do
    invitation, token = invite("retry-registration@example.com")
    attributes = registration_attributes(invitation.email_address)

    assert_no_difference [-> { User.count }, -> { Profile.count }, -> { BrandAccess.count },
        -> { BrandCredential.count }, -> { BrandAccessGrant.count }, -> { Session.count }] do
      post users_path, params: { invitation: token, user: attributes.merge(password_confirmation: "different") }
    end
    assert_response :unprocessable_entity
    assert invitation.reload.pending?

    post users_path, params: { invitation: token, user: attributes }

    assert_redirected_to "/posturacorretta/dashboard"
    assert_equal "accepted", invitation.reload.status
    assert_equal 1, User.where(email_address: invitation.email_address).count
  end

  private

    def invite(email)
      BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: email, invited_by_user: @owner)
    end

    def registration_attributes(email)
      { email_address: email, password: "brand-password", password_confirmation: "brand-password" }
    end
end
