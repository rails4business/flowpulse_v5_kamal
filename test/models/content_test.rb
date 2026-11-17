require "test_helper"

class ContentTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "content-owner@flowpulse.test", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Content owner", username: "content_owner")
    role_assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Raccolta", slug: "raccolta-contenuti", role_assignment: role_assignment)
    @course = Content.create!(node: @node, key: "corso-test", slug: "corso-test", format: "course", title: "Corso")
  end

  test "a new content starts as a private draft" do
    assert_equal "draft", @course.publication_status
    assert_equal "private", @course.publication_visibility
    assert_equal [], @course.access_modes
    assert_not @course.published_for_public?
  end

  test "key is unique across all contents" do
    duplicate = Content.new(node: @node, key: "corso-test", slug: "altro", format: "course", title: "Altro")

    assert_not duplicate.valid?
    assert duplicate.errors[:key].any?
  end

  test "slug is unique only inside the same node and parent" do
    chapter = @course.children.create!(node: @node, key: "corso-test-capitolo", slug: "capitolo", format: "chapter", title: "Capitolo")
    other_course = Content.create!(node: @node, key: "altro-corso", slug: "altro-corso", format: "course", title: "Altro corso")
    same_slug_elsewhere = other_course.children.new(node: @node, key: "altro-corso-capitolo", slug: "capitolo", format: "chapter", title: "Capitolo")
    same_slug_same_course = @course.children.new(node: @node, key: "corso-test-capitolo-2", slug: "capitolo", format: "chapter", title: "Doppione")

    assert chapter.persisted?
    assert same_slug_elsewhere.valid?, same_slug_elsewhere.errors.full_messages.to_sentence
    assert_not same_slug_same_course.valid?
  end

  test "format, publication status and access modes accept only known values" do
    @course.format = "romanzo"
    @course.publication_status = "pubblicatissimo"
    @course.access_modes = ["free", "gratis"]

    assert_not @course.valid?
    assert @course.errors[:format].any?
    assert @course.errors[:publication_status].any?
    assert @course.errors[:access_modes].any?
  end

  test "profile cards are contents of the collection node" do
    card = Content.new(node: @node, key: "scheda-insegnante", slug: "mario-rossi", format: "insegnante", title: "Mario Rossi")

    assert card.valid?, card.errors.full_messages.to_sentence
    assert_includes Content::FORMATS, "metodica"
  end

  test "a node with contents cannot be destroyed" do
    assert_not @node.destroy
    assert Content.exists?(@course.id)
  end

  test "a publication belongs to one platform and format" do
    publication = @course.publications.new(key: "youtube-video", platform: "youtube", format: "video", url: "https://youtube.com/watch?v=1")
    assert publication.valid?, publication.errors.full_messages.to_sentence

    publication.platform = "myspace"
    assert_not publication.valid?
  end

  test "a contribution has exactly one contributor, a profile or a contact" do
    contact = @profile.impegno_contacts.create!(name: "Professionista senza account")

    by_profile = @course.contributions.new(profile: @profile, role: "autore")
    by_contact = @course.contributions.new(contact: contact, role: "esperto")
    by_both = @course.contributions.new(profile: @profile, contact: contact, role: "revisore")
    by_none = @course.contributions.new(role: "revisore")

    assert by_profile.valid?, by_profile.errors.full_messages.to_sentence
    assert by_contact.valid?, by_contact.errors.full_messages.to_sentence
    assert_equal contact, by_contact.contributor
    assert_not by_both.valid?
    assert_not by_none.valid?
  end

  test "the database rejects a contribution without contributor" do
    assert_raises(ActiveRecord::StatementInvalid) do
      ContentContribution.insert_all!([{ content_id: @course.id, role: "autore", position: 0, created_at: Time.current, updated_at: Time.current }])
    end
  end

  test "a link starts from a content or from a node, never both" do
    methodology = Content.create!(node: @node, key: "metodica-test", slug: "metodica-test", format: "metodica", title: "Metodica")

    from_content = ContentLink.new(source_content: @course, target_content: methodology, kind: "metodica")
    from_node = ContentLink.new(source_node: @node, target_content: methodology, kind: "metodica")
    from_both = ContentLink.new(source_content: @course, source_node: @node, target_content: methodology, kind: "metodica")
    to_itself = ContentLink.new(source_content: methodology, target_content: methodology, kind: "metodica")

    assert from_content.valid?, from_content.errors.full_messages.to_sentence
    assert from_node.valid?, from_node.errors.full_messages.to_sentence
    assert_equal @node, from_node.source
    assert_not from_both.valid?
    assert_not to_itself.valid?
  end
end
