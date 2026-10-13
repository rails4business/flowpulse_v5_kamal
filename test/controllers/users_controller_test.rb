require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
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
    invitation, raw_token = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: "invited-new@example.com", invited_by_user: @owner)
    contact = @owner.profile.impegno_contacts.create!(name: "Invited New", email: "invited-new@example.com")
    access_request = @owner.profile.data_commitments.create!(
      created_by_profile: @owner.profile, domain: @domain, subject: @node, participant_contact: contact,
      title: "Richiesta accesso", kind: "service", status: "in_progress", starts_at: nil,
      blocks_calendar: false, pricing_type: "none", contribution_type: "unpaid",
      calendar_key: "brand:#{@node.id}:requests", calendar_label: "Richieste · PosturaCorretta",
      metadata: { "request_kind" => "access_invitation", "brand_invitation_id" => invitation.id }
    )
    get brand_invitation_path(raw_token)

    assert_no_emails do
      assert_difference [-> { User.count }, -> { Profile.count }, -> { BrandAccess.count }, -> { Session.count }], 1 do
        assert_no_difference -> { EmailVerification.count } do
          post users_path, params: { invitation: raw_token, user: { email_address: "invited-new@example.com", password: "password123", password_confirmation: "password123" } }
        end
      end
    end

    user = User.find_by!(email_address: "invited-new@example.com")
    assert user.active_registration?
    assert_not user.email_verified?
    assert_equal "accepted", invitation.reload.status
    assert_equal @node, user.profile.brand_accesses.active.first.brand_node
    assert_equal "invitation", user.sessions.last.authentication_method
    assert_equal "completed", access_request.reload.status
    assert access_request.resolved_at.present?
    assert_redirected_to "/posturacorretta/dashboard"
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
end
