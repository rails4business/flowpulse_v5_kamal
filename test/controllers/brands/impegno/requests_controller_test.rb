require "test_helper"

module Brands
  module Impegno
    class RequestsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = User.create!(email_address: "request-rejection-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        @admin.create_profile!(display_name: "Request Admin", username: "request_admin")
        @participant = User.create!(email_address: "request-rejection-participant@example.com", password: "password123", password_confirmation: "password123")
        @participant.create_profile!(display_name: "Participant", username: "request_participant")
        @domain = Domain.create!(hostname: "request-rejection.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
        @event = DataEvent.create!(title: "Lezione richiesta", classification: "class", node_kind: "root", status: "confirmed", visibility: "public", published_at: Time.current, registration_status: "open", registration_mode: "required", booking_mode: "parent", service_scope: "private", position: 0, domain: @domain, created_by_profile: @admin.profile)
        @commitment = DataCommitment.create!(profile: @participant.profile, created_by_profile: @participant.profile, domain: @domain, requested_data_event: @event, title: "Richiesta · Lezione", kind: "academy", status: "requested", starts_at: 1.day.from_now, blocks_calendar: false, pricing_type: "none", contribution_type: "unpaid", metadata: { "request_source" => "test" })
      end

      test "superadmin rejects a pending request and preserves its audit history" do
        post session_url, params: { email_address: @admin.email_address, password: "password123" }

        patch reject_impegno_request_url(@commitment), params: { brand: "posturacorretta", rejection_reason: "Posti non disponibili" }

        assert_redirected_to impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests")
        @commitment.reload
        assert_equal "cancelled", @commitment.status
        assert_not @commitment.blocks_calendar?
        assert_equal "test", @commitment.metadata["request_source"]
        assert_equal "Posti non disponibili", @commitment.metadata.dig("rejection", "reason")
        assert_equal @admin.profile.id, @commitment.metadata.dig("rejection", "rejected_by_profile_id")
        assert @commitment.metadata.dig("rejection", "rejected_at").present?
      end

      test "superadmin confirms a request from a day window" do
        @event.update!(responsible_profile: @admin.profile, operator_roles: [{ "role" => "teacher", "profile_id" => @admin.profile.id }])
        day = DataEvent.create!(title: "Pomeriggio", classification: "class", node_kind: "day", parent: @event, domain: @domain, created_by_profile: @admin.profile, starts_at: Time.zone.parse("2026-09-10 15:00"), ends_at: Time.zone.parse("2026-09-10 18:00"), status: "proposed")
        @commitment.update!(requested_data_event: day, starts_at: Time.zone.parse("2026-09-10 15:00"), ends_at: Time.zone.parse("2026-09-10 16:00"))
        post session_url, params: { email_address: @admin.email_address, password: "password123" }

        assert_difference("DataEvent.where(node_kind: 'session').count", 1) do
          patch confirm_impegno_request_url(@commitment), params: { brand: "posturacorretta" }
        end

        assert_redirected_to impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests", request_id: @commitment.id)
        assert_equal "confirmed", @commitment.reload.status
        assert @commitment.data_event.present?

        session = @commitment.data_event
        patch cancel_confirmed_impegno_request_url(@commitment), params: { brand: "posturacorretta", cancellation_reason: "Cambio programma" }

        assert_redirected_to impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests")
        assert_equal "cancelled", @commitment.reload.status
        assert_not @commitment.blocks_calendar?
        assert_equal "Cambio programma", @commitment.metadata.dig("cancellation", "reason")
        assert_equal "cancelled", session.reload.status
      end

      test "non superadmin cannot reject a request" do
        post session_url, params: { email_address: @participant.email_address, password: "password123" }

        patch reject_impegno_request_url(@commitment), params: { rejection_reason: "Non autorizzato" }

        assert_response :not_found
        assert_equal "requested", @commitment.reload.status
        assert_nil @commitment.metadata["rejection"]

        patch confirm_impegno_request_url(@commitment)
        assert_response :not_found
        assert_equal "requested", @commitment.reload.status

        @commitment.update!(status: "confirmed", participation_role: "participant")
        patch cancel_confirmed_impegno_request_url(@commitment)
        assert_response :not_found
        assert_equal "confirmed", @commitment.reload.status
      end

      test "an already processed request cannot be rejected again" do
        @commitment.update!(status: "cancelled")
        post session_url, params: { email_address: @admin.email_address, password: "password123" }

        patch reject_impegno_request_url(@commitment)

        assert_response :not_found
        assert_nil @commitment.reload.metadata["rejection"]
      end

      test "participant withdraws an own pending request and preserves audit history" do
        post session_url, params: { email_address: @participant.email_address, password: "password123" }

        patch withdraw_impegno_request_url(@commitment)

        assert_redirected_to posturacorretta_data_event_url(@event)
        assert_equal "cancelled", @commitment.reload.status
        assert_not @commitment.blocks_calendar?
        assert_equal @participant.profile.id, @commitment.metadata.dig("withdrawal", "withdrawn_by_profile_id")
        assert @commitment.metadata.dig("withdrawal", "withdrawn_at").present?
      end

      test "participant cannot withdraw another profile request or a confirmed one" do
        other = User.create!(email_address: "other-request-owner@example.com", password: "password123", password_confirmation: "password123")
        other.create_profile!(display_name: "Other", username: "other_request_owner")
        post session_url, params: { email_address: other.email_address, password: "password123" }

        patch withdraw_impegno_request_url(@commitment)
        assert_response :not_found
        assert_equal "requested", @commitment.reload.status

        delete session_url
        @commitment.update!(status: "confirmed")
        post session_url, params: { email_address: @participant.email_address, password: "password123" }
        patch withdraw_impegno_request_url(@commitment)
        assert_response :not_found
        assert_equal "confirmed", @commitment.reload.status
      end
    end
  end
end
