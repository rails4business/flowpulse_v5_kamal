require "test_helper"

class BrandInvitations::IssuerTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email_address: "issuer-owner@example.com", password: "password123")
    assignment = RoleAssignment.create!(profile: @owner.create_profile!(display_name: "Owner"), role: :ideatore)
    @brand = Node.create!(title: "Issuer Brand", role_assignment: assignment)
    @domain = Domain.create!(hostname: "issuer.example", node: @brand, role_assignment: assignment)
    contact = @owner.profile.impegno_contacts.create!(name: "Person", email: "issuer-person@example.com")
    @request = BrandRequest.create!(
      domain: @domain, brand_node: @brand, subject: @brand, participant_contact: contact,
      title: "Access", kind: "access", status: "open"
    )
  end

  test "failed regeneration preserves the previous invitation and request state" do
    previous, = issue

    assert_no_difference -> { BrandInvitation.count } do
      assert_raises(ActiveRecord::RecordInvalid) do
        BrandInvitations::Issuer.new(actor: @owner).issue!(domain: @domain, email_address: "invalid", brand_request: @request)
      end
    end

    assert previous.reload.pending?
    assert_equal "invited", @request.reload.status
  end

  test "successful regeneration revokes only the previous pending invitation" do
    previous, = issue
    invitation, = issue

    assert_equal "revoked", previous.reload.status
    assert invitation.reload.pending?
    assert_equal @request, invitation.brand_request
    assert_equal @owner.profile, @request.reload.assigned_to_profile
    assert_nil invitation.role_code
  end

  test "a closed request cannot generate a new invitation" do
    @request.close_as!("rejected")

    assert_no_difference -> { BrandInvitation.count } do
      assert_raises(ArgumentError) { issue }
    end
  end

  test "an unrelated project cannot be used to authorize an invitation" do
    outside = Node.create!(title: "Outside", role_assignment: @brand.role_assignment)
    @request.update!(subject: outside)

    assert_no_difference -> { BrandInvitation.count } do
      assert_raises(BrandAccesses::Authorization::NotAuthorized) { issue }
    end
  end

  test "GeneraImpresa manager can issue invitations but its legacy owner cannot" do
    @brand.update!(slug: "generaimpresa", operator_roles: %w[gestore_generaimpresa])
    assert_raises(BrandAccesses::Authorization::NotAuthorized) { issue }
    manager = User.create!(email_address: "issuer-manager@example.com", password: "password123")
    profile = manager.create_profile!(display_name: "Manager")
    access = BrandAccess.create!(profile: profile, source_domain: @domain)
    role = RoleAssignment.create!(
      profile: profile, brand_access: access, role: :operator, role_operator: "gestore_generaimpresa",
      context: @brand, parent: @brand.role_assignment
    )
    access.select_role_assignment!(role)

    context = AccessContext::Resolver.new(user: manager, domain: @domain).resolve
    invitation, = BrandInvitations::Issuer.new(actor: manager, context: context).issue!(
      domain: @domain, email_address: @request.participant_contact.email, brand_request: @request
    )

    assert invitation.pending?
    assert_equal manager, invitation.invited_by_user
    assert_equal manager.profile, @request.reload.assigned_to_profile
  end

  private

    def issue
      BrandInvitations::Issuer.new(actor: @owner).issue!(
        domain: @domain, email_address: @request.participant_contact.email, brand_request: @request
      )
    end
end
