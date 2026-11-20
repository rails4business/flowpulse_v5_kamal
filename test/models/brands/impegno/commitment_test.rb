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

      test "a concluded publish decision is linked to its content as history but does not publish it" do
        content = create_content

        commitment = create_publication_decision(content_key: content.key, change_kind: "publish", publication_status: "published", published_at: 1.hour.ago)

        assert_equal content, commitment.content
        assert_includes content.publication_decisions, commitment
        content.reload
        assert_equal "draft", content.publication_status
        assert_equal "private", content.publication_visibility
        assert_nil content.published_at
      end

      test "a planned decision takes its status and date from the moment it is concluded" do
        content = create_content
        first = create_publication_decision(content_key: content.key, change_kind: "publish", publication_status: "published", published_at: 1.day.ago)
        planned = create_publication_decision(content_key: content.key, change_kind: "unpublish", publication_status: "published", status: "planned")
        ended_at = 1.minute.ago.change(usec: 0)

        planned.update!(status: "completed", actual_ended_at: ended_at)

        assert_equal "draft", planned.publication_status
        assert_nil planned.published_at
        assert_equal first, planned.previous_publication_commitment
      end

      test "a decision recorded as concluded without a status takes it from the change kind" do
        content = create_content

        commitment = create_publication_decision(content_key: content.key, change_kind: "archive", publication_status: "", visibility: "private")

        assert_equal "archived", commitment.publication_status
        assert_nil commitment.published_at
      end

      test "a decision not yet concluded leaves the content unchanged" do
        content = create_content

        create_publication_decision(content_key: content.key, change_kind: "publish", publication_status: "published", status: "planned")

        assert_equal "draft", content.reload.publication_status
      end

      test "a decision on a platform publication is linked to its content" do
        content = create_content
        publication = content.publications.create!(key: "youtube-video", platform: "youtube", format: "video")

        commitment = create_publication_decision(content_key: content.key, content_publication: publication, change_kind: "publish", publication_status: "published", published_at: 1.hour.ago)

        assert_equal content, commitment.content
        assert_equal "draft", publication.reload.publication_status
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

      test "enrollments and chapter completions link to their Content by slug" do
        content = create_content
        course = Content.create!(node: content.node, key: "corso-impegni", slug: "corso", format: "course", title: "Corso")
        content.update!(parent: course)

        enrollment = create_learning_record(content_key: "corso", metadata: { "record_type" => "course_enrollment", "course_slug" => "corso" })
        completion = create_learning_record(content_key: "capitolo", metadata: { "record_type" => "chapter_completion", "course_slug" => "corso" })
        other_course = create_learning_record(content_key: "capitolo", metadata: { "record_type" => "chapter_completion", "course_slug" => "altro-corso" })

        assert_equal course, enrollment.content
        assert_equal "corso", enrollment.content_key
        assert_equal content, completion.content
        assert_nil other_course.content, "lo slug del capitolo vale solo dentro il suo corso"
      end

      test "new learning records link by Content key and follow its current slug" do
        content = create_content
        course = Content.create!(node: content.node, key: "corso-impegni", slug: "corso", format: "course", title: "Corso")
        content.update!(parent: course)

        enrollment = create_learning_record(content_key: "corso-impegni", metadata: { "record_type" => "course_enrollment", "course_slug" => "corso" })
        completion = create_learning_record(content_key: "capitolo-da-pubblicare", metadata: { "record_type" => "chapter_completion", "course_slug" => "corso", "chapter_slug" => "capitolo" })
        assert_equal course, enrollment.content
        assert_equal content, completion.content

        course.update!(slug: "corso-rinominato")
        content.update!(slug: "capitolo-rinominato")
        completion.reload
        assert_equal "corso-rinominato", enrollment.reload.learning_slug
        assert_equal "capitolo-rinominato", completion.learning_slug
        assert_equal "corso-rinominato", completion.learning_course_slug
      end

      test "unlinked learning records keep the slugs they were saved with" do
        completion = create_learning_record(content_key: "vecchio-capitolo", metadata: { "record_type" => "chapter_completion", "course_slug" => "vecchio-corso", "chapter_slug" => "vecchio-capitolo" })

        assert_nil completion.content
        assert_equal "vecchio-capitolo", completion.learning_slug
        assert_equal "vecchio-corso", completion.learning_course_slug
      end

      private

        def create_content
          role_assignment = RoleAssignment.create!(profile: @profile, role: :creator_of_worlds)
          node = Node.create!(title: "Raccolta", slug: "raccolta-impegni", role_assignment: role_assignment)
          Content.create!(node: node, key: "capitolo-da-pubblicare", slug: "capitolo", format: "chapter", title: "Capitolo")
        end

        def create_learning_record(content_key:, metadata:)
          @profile.data_commitments.create!(
            created_by_profile: @profile,
            domain: @domain,
            title: "Percorso",
            kind: "academy",
            status: "completed",
            starts_at: Time.current,
            blocks_calendar: false,
            pricing_type: "none",
            contribution_type: "unpaid",
            content_key: content_key,
            metadata: metadata
          )
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
