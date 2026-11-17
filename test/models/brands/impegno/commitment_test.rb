require "test_helper"

module Brands
  module Impegno
    class CommitmentTest < ActiveSupport::TestCase
      setup do
        user = User.create!(email_address: "request-owner@example.com", password: "password123", password_confirmation: "password123")
        @profile = user.create_profile!(display_name: "Request owner", username: "request_owner")
        @domain = Domain.create!(hostname: "requests.example.test", locale: "it", target_controller: "home", target_action: "index")
      end

      test "an anonymous contact request may remain unscheduled" do
        contact = @profile.impegno_contacts.create!(name: "Persona interessata", phone: "+39 030 000000")
        commitment = @profile.data_commitments.new(
          created_by_profile: @profile,
          domain: @domain,
          participant_contact: contact,
          title: "Richiesta informazioni",
          kind: "service",
          status: "requested",
          starts_at: nil,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid"
        )

        assert commitment.valid?, commitment.errors.full_messages.to_sentence
      end

      test "an unscheduled request requires email or telephone" do
        contact = @profile.impegno_contacts.create!(name: "Persona senza recapiti")
        commitment = @profile.data_commitments.new(
          created_by_profile: @profile,
          domain: @domain,
          participant_contact: contact,
          title: "Richiesta informazioni",
          kind: "service",
          status: "requested",
          starts_at: nil,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid"
        )

        assert_not commitment.valid?
        assert_includes commitment.errors[:participant_contact], "deve avere almeno un indirizzo email o un numero di telefono"
      end

      test "a workbench draft may remain unscheduled without blocking the calendar" do
        commitment = @profile.data_commitments.new(
          created_by_profile: @profile,
          domain: @domain,
          title: "Idea da organizzare",
          kind: "work",
          status: "draft",
          starts_at: nil,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid",
          metadata: {
            "workbench" => {
              "inbox" => true,
              "item_type" => "undecided",
              "organization" => "undecided",
              "classification_status" => "unclassified"
            }
          }
        )

        assert commitment.valid?, commitment.errors.full_messages.to_sentence
        assert commitment.workbench_item?
      end

      test "an ordinary personal draft still requires a date" do
        commitment = @profile.data_commitments.new(
          created_by_profile: @profile,
          domain: @domain,
          title: "Bozza ordinaria",
          kind: "work",
          status: "draft",
          starts_at: nil,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid"
        )

        assert_not commitment.valid?
        assert commitment.errors.added?(:starts_at, :blank)
      end

      test "workbench metadata uses the supported vocabulary" do
        commitment = @profile.data_commitments.new(
          created_by_profile: @profile,
          domain: @domain,
          title: "Voce non valida",
          kind: "work",
          status: "draft",
          starts_at: nil,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid",
          metadata: {
            "workbench" => {
              "inbox" => true,
              "item_type" => "qualunque",
              "organization" => "undecided",
              "classification_status" => "unclassified"
            }
          }
        )

        assert_not commitment.valid?
        assert_includes commitment.errors[:metadata], "contiene item_type non valido"
      end

      test "a concluded publish decision publishes the content linked by its key" do
        content = create_content
        decided_at = Time.zone.parse("2026-11-17 10:00")

        commitment = create_publication_decision(content_key: content.key, change_kind: "publish", publication_status: "published", published_at: decided_at)

        assert_equal content, commitment.content
        content.reload
        assert_equal "published", content.publication_status
        assert_equal "public", content.publication_visibility
        assert_equal ["free"], content.access_modes
        assert_equal decided_at, content.published_at
        assert_nil content.revised_at
      end

      test "an update decision sets the revision date and keeps the first publication date" do
        content = create_content
        first = Time.zone.parse("2026-11-01 10:00")
        revised = Time.zone.parse("2026-11-17 10:00")
        create_publication_decision(content_key: content.key, change_kind: "publish", publication_status: "published", published_at: first)

        create_publication_decision(content_key: content.key, change_kind: "update", publication_status: "published", published_at: revised)

        content.reload
        assert_equal first, content.published_at
        assert_equal revised, content.revised_at
      end

      test "an unpublish decision brings the content back to draft" do
        content = create_content
        create_publication_decision(content_key: content.key, change_kind: "publish", publication_status: "published", published_at: 1.day.ago)

        create_publication_decision(content_key: content.key, change_kind: "unpublish", publication_status: "draft", visibility: "private")

        content.reload
        assert_equal "draft", content.publication_status
        assert_nil content.published_at
      end

      test "a decision not yet concluded leaves the content unchanged" do
        content = create_content

        create_publication_decision(content_key: content.key, change_kind: "publish", publication_status: "published", status: "planned")

        assert_equal "draft", content.reload.publication_status
      end

      test "a decision on a platform publication updates only that publication" do
        content = create_content
        publication = content.publications.create!(key: "youtube-video", platform: "youtube", format: "video")

        commitment = create_publication_decision(content_key: content.key, content_publication: publication, change_kind: "publish", publication_status: "published", published_at: 1.hour.ago)

        assert_equal content, commitment.content
        assert_equal "published", publication.reload.publication_status
        assert_equal "draft", content.reload.publication_status
      end

      test "a decision without a matching content keeps working as before" do
        commitment = create_publication_decision(content_key: "chiave-solo-nel-yaml", change_kind: "publish", publication_status: "published")

        assert commitment.persisted?
        assert_nil commitment.content
      end

      test "content_key must match the linked content" do
        content = create_content
        commitment = @profile.data_commitments.new(publication_decision_attributes(content_key: "altra-chiave", change_kind: "publish", publication_status: "published"))
        commitment.content = content

        assert_not commitment.valid?
        assert_includes commitment.errors[:content_key], "non corrisponde al contenuto collegato"
      end

      private

        def create_content
          role_assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
          node = Node.create!(title: "Raccolta", slug: "raccolta-impegni", role_assignment: role_assignment)
          Content.create!(node: node, key: "capitolo-da-pubblicare", slug: "capitolo", format: "chapter", title: "Capitolo")
        end

        def create_publication_decision(**options)
          @profile.data_commitments.create!(publication_decision_attributes(**options))
        end

        def publication_decision_attributes(content_key:, change_kind:, publication_status:, visibility: "public", status: "completed", published_at: nil, content_publication: nil)
          {
            created_by_profile: @profile,
            domain: @domain,
            title: "Decisione #{change_kind}",
            kind: "content",
            status: status,
            starts_at: Time.current,
            blocks_calendar: false,
            pricing_type: "none",
            contribution_type: "unpaid",
            content_key: content_key,
            content_publication: content_publication,
            publish_on_completion: true,
            publication_status: publication_status,
            publication_visibility: visibility,
            publication_change_kind: change_kind,
            access_modes: ["free"],
            published_at: published_at
          }
        end
    end
  end
end
