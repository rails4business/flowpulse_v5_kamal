require "test_helper"

class BrandRequestProfileLinkerTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email_address: "linker-owner@example.com", password: "password123")
    owner_profile = @owner.create_profile!(display_name: "Owner")
    assignment = RoleAssignment.create!(profile: owner_profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Linker Brand", role_assignment: assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "linker.example", node: @node, role_assignment: assignment, locale: "it")
  end

  test "links through an accepted invitation, a verified email or an invitation to that email" do
    invited = person("invited@example.com")
    by_invitation = request_for("invited@example.com", status: "accepted")
    invitation, = BrandInvitation.issue!(brand_node: @node, source_domain: @domain, email_address: "invited@example.com", invited_by_user: @owner, brand_request: by_invitation)
    invitation.accept!(invited)

    verified = person("verified@example.com", verified: true)
    by_verified_email = request_for("verified@example.com", status: "closed")

    other_request = request_for("invited@example.com")

    linker = BrandRequestProfileLinker.new.call(apply: true)

    assert_equal invited.profile, by_invitation.reload.requester_profile
    assert_equal verified.profile, by_verified_email.reload.requester_profile
    assert_equal invited.profile, other_request.reload.requester_profile
    assert_equal "closed", by_verified_email.status
    assert_equal ["email verificata", "invito", "invito a questa email"], linker.linked.map(&:reason).sort
    assert_empty linker.to_review
  end

  test "an unverified email match is only listed for review and the dry run changes nothing" do
    person("unverified@example.com")
    unverified_request = request_for("unverified@example.com")
    verified = person("dry-run@example.com", verified: true)
    dry_run_request = request_for("dry-run@example.com")

    linker = BrandRequestProfileLinker.new.call

    assert_nil unverified_request.reload.requester_profile
    assert_nil dry_run_request.reload.requester_profile
    assert_equal [unverified_request], linker.to_review.map(&:brand_request)
    assert_equal [[dry_run_request, verified.profile]], linker.linked.map { |match| [match.brand_request, match.profile] }
  end

  test "requests that already have a profile are left untouched" do
    someone = person("already@example.com", verified: true)
    other = person("other@example.com")
    linked_request = request_for("already@example.com")
    linked_request.update!(requester_profile: other.profile)

    BrandRequestProfileLinker.new.call(apply: true)

    assert_equal other.profile, linked_request.reload.requester_profile
    assert_not_equal someone.profile, linked_request.requester_profile
  end

  private

    def person(email, verified: false)
      User.create!(email_address: email, password: "password123", email_verified_at: (Time.current if verified)).tap do |user|
        user.create_profile!(display_name: email.split("@").first)
      end
    end

    def request_for(email, status: "open")
      contact = @owner.profile.impegno_contacts.create!(name: email.split("@").first, email:)
      BrandRequest.create!(domain: @domain, brand_node: @node, subject: @node, participant_contact: contact,
        title: "Richiesta accesso", kind: "access", status:)
    end
end
