require "test_helper"

class BrandInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email_address: "brand-invitation-owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    profile = @owner.create_profile!(display_name: "Brand Owner")
    assignment = RoleAssignment.create!(profile:, role: :creator_of_worlds)
    @node = Node.create!(
      title: "PosturaCorretta",
      role_assignment: assignment,
      status: "published",
      visibility: "public"
    )
    @domain = Domain.create!(
      hostname: "posturacorretta.org",
      node: @node,
      role_assignment: assignment,
      locale: "it",
      primary: true,
      site_title: "PosturaCorretta"
    )
  end

  test "brand administrator generates a manual invitation without email" do
    post session_path, params: { email_address: @owner.email_address, password: "password123" }

    assert_difference -> { BrandInvitation.count }, 1 do
      assert_no_emails do
        post brand_invitations_path, params: {
          domain_id: @domain.id,
          email_address: "invited-person@example.com"
        }
      end
    end

    invitation = BrandInvitation.order(:created_at).last
    assert_equal @node, invitation.brand_node
    assert_equal @domain, invitation.source_domain
    assert_match %r{/brand-invitations/}, flash[:invitation_url]
  end

  test "invitation sends a new person directly to registration" do
    invitation, raw_token = BrandInvitation.issue!(
      brand_node: @node,
      source_domain: @domain,
      email_address: "invited-person@example.com",
      invited_by_user: @owner
    )

    host! @domain.hostname
    get brand_invitation_path(raw_token)

    assert_redirected_to new_user_path(invitation: raw_token)
    assert invitation.pending?
  end

  test "invitation sends an existing global account without this Brand credential to setup" do
    existing_user = User.create!(email_address: "existing-invited@example.com", password: "password123")
    existing_user.create_profile!(display_name: "Existing invited")
    invitation, raw_token = BrandInvitation.issue!(
      brand_node: @node,
      source_domain: @domain,
      email_address: existing_user.email_address,
      invited_by_user: @owner
    )

    host! @domain.hostname
    get brand_invitation_path(raw_token)

    assert_redirected_to new_user_path(invitation: raw_token)
    assert invitation.pending?
  end

  test "invitation sends an existing Brand credential directly to login" do
    existing_user = User.create!(email_address: "existing-brand@example.com", password: "global-password")
    profile = existing_user.create_profile!(display_name: "Existing brand")
    access = BrandAccess.create!(profile:, source_domain: @domain)
    BrandCredential.create!(
      brand_access: access,
      brand_node: @node,
      email_address: existing_user.email_address,
      password: "brand-password"
    )
    invitation, raw_token = BrandInvitation.issue!(
      brand_node: @node,
      source_domain: @domain,
      email_address: existing_user.email_address,
      invited_by_user: @owner
    )

    host! @domain.hostname
    get brand_invitation_path(raw_token)

    assert_redirected_to new_session_path(invitation: raw_token)
    assert invitation.pending?
  end
end
