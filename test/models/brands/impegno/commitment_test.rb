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
    end
  end
end
