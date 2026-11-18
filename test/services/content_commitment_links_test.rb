require "test_helper"

class ContentCommitmentLinksTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "links-owner@flowpulse.test", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Redazione", username: "links_owner")
    @domain = Domain.create!(hostname: "links.example.test", locale: "it", target_controller: "home", target_action: "index")
    role_assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Raccolta", slug: "raccolta-links", role_assignment: role_assignment)
  end

  test "links commitments that only have a key and replays their decisions in order" do
    published = Time.zone.parse("2026-11-01 10:00")
    revised = Time.zone.parse("2026-11-10 10:00")
    decision(change_kind: "publish", publication_status: "published", published_at: published)
    decision(change_kind: "update", publication_status: "published", published_at: revised)
    content = Content.create!(node: @node, key: "capitolo-links", slug: "capitolo", format: "chapter", title: "Capitolo")

    result = ContentCommitmentLinks.new.link!

    assert_equal 2, result.linked
    assert_equal 2, result.replayed
    assert_empty result.missing
    content.reload
    assert_equal 2, content.data_commitments.count
    assert_equal "published", content.publication_status
    assert_equal published, content.published_at
    assert_equal revised, content.revised_at
  end

  test "the last concluded decision wins" do
    decision(change_kind: "publish", publication_status: "published", published_at: 2.days.ago)
    decision(change_kind: "unpublish", publication_status: "draft", published_at: nil, visibility: "private")
    content = Content.create!(node: @node, key: "capitolo-links", slug: "capitolo", format: "chapter", title: "Capitolo")

    ContentCommitmentLinks.new.link!

    assert_equal "draft", content.reload.publication_status
    assert_nil content.published_at
  end

  test "reports commitments without a content and leaves them unlinked" do
    commitment = decision(change_kind: "publish", publication_status: "published", published_at: 1.day.ago)

    result = ContentCommitmentLinks.new.link!

    assert_equal 0, result.linked
    assert_equal ["impegno #{commitment.id} (content): capitolo-links"], result.missing
    assert_nil commitment.reload.content_id
  end

  test "dry run changes nothing" do
    decision(change_kind: "publish", publication_status: "published", published_at: 1.day.ago)
    content = Content.create!(node: @node, key: "capitolo-links", slug: "capitolo", format: "chapter", title: "Capitolo")

    result = ContentCommitmentLinks.new.link!(dry_run: true)

    assert_equal 1, result.linked
    assert_equal 0, content.data_commitments.count
    assert_equal "draft", content.reload.publication_status
  end

  private

    # Una decisione registrata prima che il Content esistesse: ha solo content_key.
    def decision(change_kind:, publication_status:, published_at:, visibility: "public")
      @profile.data_commitments.create!(
        created_by_profile: @profile,
        domain: @domain,
        title: "Decisione #{change_kind}",
        kind: "content",
        status: "completed",
        starts_at: Time.current,
        blocks_calendar: false,
        pricing_type: "none",
        contribution_type: "unpaid",
        content_key: "capitolo-links",
        publish_on_completion: true,
        publication_status: publication_status,
        publication_visibility: visibility,
        publication_change_kind: change_kind,
        access_modes: ["free"],
        published_at: published_at
      )
    end
end
