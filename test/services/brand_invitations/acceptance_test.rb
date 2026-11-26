require "test_helper"

class BrandInvitations::AcceptanceTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email_address: "acceptance-owner@example.com", password: "password123")
    assignment = RoleAssignment.create!(profile: @owner.create_profile!(display_name: "Owner"), role: :ideatore)
    @brand = Node.create!(title: "Acceptance Brand", role_assignment: assignment)
    @domain = Domain.create!(hostname: "acceptance.example", node: @brand, role_assignment: assignment)
    @user = User.create!(email_address: "acceptance-person@example.com", password: "global-password")
    @profile = @user.create_profile!(display_name: "Person")
    @invitation, = BrandInvitation.issue!(
      brand_node: @brand, source_domain: @domain, email_address: @user.email_address, invited_by_user: @owner
    )
  end

  test "reuses the existing profile and access and records a grant without assigning a role" do
    access = BrandAccess.create!(profile: @profile, source_domain: @domain)

    assert_no_difference [-> { User.count }, -> { Profile.count }, -> { BrandAccess.count }, -> { RoleAssignment.count }] do
      assert_difference -> { BrandAccessGrant.count }, 1 do
        result = register
        assert_equal access, result.brand_access
        assert result.brand_credential.authenticate("brand-password")
      end
    end

    assert @user.reload.authenticate("global-password")
    assert_equal @owner.profile, access.grants.first.granted_by_profile
  end

  test "invalid credential rolls back the new person profile access and request changes" do
    @invitation.update!(email_address: "new-person@example.com")
    contact = @owner.profile.impegno_contacts.create!(name: "New person", email: @invitation.email_address)
    request = BrandRequest.create!(
      domain: @domain, brand_node: @brand, subject: @brand, participant_contact: contact,
      title: "Access", kind: "access", status: "invited"
    )
    @invitation.update!(brand_request: request)
    user = User.new(email_address: @invitation.email_address)

    assert_no_difference [-> { User.count }, -> { Profile.count }, -> { BrandAccess.count },
        -> { BrandCredential.count }, -> { BrandAccessGrant.count }] do
      assert_raises(ActiveRecord::RecordInvalid) do
        acceptance.register!(user: user, password: "password123", password_confirmation: "different")
      end
    end

    assert @invitation.reload.pending?
    assert_equal "invited", request.reload.status
    assert_nil request.requester_profile
  end

  test "a stale copy of an accepted invitation cannot be reused" do
    stale = BrandInvitation.find(@invitation.id)
    register

    assert_no_difference [-> { BrandAccess.count }, -> { BrandCredential.count }, -> { BrandAccessGrant.count }] do
      assert_raises(BrandInvitations::Acceptance::Invalid) do
        BrandInvitations::Acceptance.new(invitation: stale, domain: @domain).register!(
          user: @user, password: "replacement", password_confirmation: "replacement"
        )
      end
    end
    assert @profile.brand_accesses.first.brand_credential.authenticate("brand-password")
  end

  test "an invitation issued before access revocation cannot reactivate access" do
    access = BrandAccess.create!(profile: @profile, source_domain: @domain)
    travel 1.minute do
      access.cancel!
    end

    assert_raises(BrandInvitations::Acceptance::Invalid) { register }
    assert_equal "cancelled", access.reload.status
    assert @invitation.reload.pending?
    assert_nil access.brand_credential
  end

  test "a new invitation reactivates access using the existing credential without changing its password" do
    access = BrandAccess.create!(profile: @profile, source_domain: @domain)
    credential = access.create_brand_credential!(brand_node: @brand, email_address: @user.email_address, password: "original-password")
    access.cancel!
    travel 1.minute do
      @invitation, = BrandInvitation.issue!(
        brand_node: @brand, source_domain: @domain, email_address: @user.email_address, invited_by_user: @owner
      )

      assert_no_difference [-> { BrandAccess.count }, -> { BrandCredential.count }] do
        acceptance.accept!(user: @user, credential: credential)
      end
    end

    assert access.reload.active?
    assert credential.reload.authenticate("original-password")
    assert_equal "accepted", @invitation.reload.status
  end

  test "acceptance does not replace an existing credential" do
    access = BrandAccess.create!(profile: @profile, source_domain: @domain)
    credential = access.create_brand_credential!(brand_node: @brand, email_address: @user.email_address, password: "original-password")

    assert_raises(BrandInvitations::Acceptance::Invalid) { register }

    assert credential.reload.authenticate("original-password")
    assert @invitation.reload.pending?
    assert_empty access.grants
  end

  test "an invitation cannot be accepted after its issuer loses authority" do
    other = User.create!(email_address: "new-acceptance-owner@example.com", password: "password123")
    assignment = RoleAssignment.create!(profile: other.create_profile!(display_name: "New owner"), role: :ideatore)
    @brand.update!(role_assignment: assignment)

    assert_no_difference -> { BrandAccess.count } do
      assert_raises(BrandAccesses::Authorization::NotAuthorized) { register }
    end
    assert @invitation.reload.pending?
  end

  test "request acceptance records the project grant and preserves unrelated project grants on revocation" do
    project = Node.create!(title: "Invited project", parent: @brand, role_assignment: @brand.role_assignment)
    other = Node.create!(title: "Other project", parent: @brand, role_assignment: @brand.role_assignment)
    request = BrandRequest.create!(
      domain: @domain, brand_node: @brand, subject: project, requester_profile: @profile,
      title: "Project access", kind: "access", status: "invited"
    )
    @invitation.update!(brand_request: request)
    access = BrandAccess.create!(profile: @profile, source_domain: @domain, grant_managed: true)
    other_grant = BrandAccessGrants::Manager.new(actor: @owner).grant!(brand_access: access, node: other)
    register

    grant = access.grants.find_by!(node: project)
    assert_equal request, grant.brand_request
    assert_equal @profile, request.reload.requester_profile
    BrandAccessGrants::Manager.new(actor: @owner).revoke!(grant)

    assert access.reload.active?
    assert other_grant.reload.active?
    assert_equal "revoked", grant.reload.status
  end

  test "acceptance rejects a request already linked to another profile" do
    request = BrandRequest.create!(
      domain: @domain, brand_node: @brand, subject: @brand, requester_profile: @owner.profile,
      title: "Access", kind: "access", status: "invited"
    )
    @invitation.update!(brand_request: request)

    assert_no_difference -> { BrandAccess.count } do
      assert_raises(BrandInvitations::Acceptance::Invalid) { register }
    end
    assert_equal @owner.profile, request.reload.requester_profile
  end

  private

    def acceptance
      BrandInvitations::Acceptance.new(invitation: @invitation, domain: @domain)
    end

    def register
      acceptance.register!(user: @user, password: "brand-password", password_confirmation: "brand-password")
    end
end
