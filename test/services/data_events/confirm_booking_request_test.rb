require "test_helper"

module DataEvents
  class ConfirmBookingRequestTest < ActiveSupport::TestCase
    setup do
      admin_user = User.create!(email_address: "booking-confirm-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
      @admin = admin_user.create_profile!(display_name: "Superadmin")
      organizer_user = User.create!(email_address: "booking-confirm-organizer@example.com", password: "password123", password_confirmation: "password123")
      @organizer = organizer_user.create_profile!(display_name: "Professionista")
      participant_user = User.create!(email_address: "booking-confirm-participant@example.com", password: "password123", password_confirmation: "password123")
      @participant = participant_user.create_profile!(display_name: "Partecipante")
      @domain = Domain.create!(hostname: "booking-confirm.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
      @root = DataEvent.create!(title: "Percorso", classification: "path", node_kind: "root", domain: @domain, created_by_profile: @organizer, responsible_profile: @organizer, operator_roles: [{ "role" => "professional", "profile_id" => @organizer.id }])
      @day = DataEvent.create!(title: "Pomeriggio", classification: "path", node_kind: "day", parent: @root, domain: @domain, created_by_profile: @organizer, starts_at: at(15), ends_at: at(18), status: "proposed")
    end

    test "confirmation creates a session and both calendar commitments" do
      request = booking_request(
        requested_data_event: @day, starts_at: at(15), ends_at: at(16),
        agreement_snapshot: { "duration_minutes" => 60, "price_cents" => 2_500, "currency" => "EUR" }
      )

      result = ConfirmBookingRequest.new(commitment: request, confirmed_by_profile: @admin).call

      session = result.fetch(:session)
      assert_equal "session", session.node_kind
      assert_equal @day, session.parent
      assert_equal "confirmed", session.status
      assert_equal session, request.reload.data_event
      assert_equal "confirmed", request.status
      assert request.blocks_calendar?
      assert_equal "profile:#{@participant.id}", request.calendar_key
      assert_equal 2_500, request.agreed_price_cents
      assert_equal "EUR", request.agreed_currency
      assert_equal 60, request.agreed_duration_minutes
      organizer_commitment = result.fetch(:organizer_commitment)
      assert_equal @organizer, organizer_commitment.assignee_profile
      assert_equal "professional", organizer_commitment.participation_role
      assert organizer_commitment.blocks_calendar?
    end

    test "contact participant receives a separate contact calendar" do
      contact = Brands::Impegno::Contact.create!(profile: @participant, name: "Persona assistita", kind: "person")
      request = booking_request(requested_data_event: @day, starts_at: at(16), ends_at: at(17), participant_contact: contact)

      ConfirmBookingRequest.new(commitment: request, confirmed_by_profile: @admin).call

      assert_equal "contact:#{contact.id}", request.reload.calendar_key
      assert_equal "Persona assistita", request.calendar_label
      assert_nil request.assignee_profile
    end

    test "an organizer conflict rolls back session and participant confirmation" do
      DataCommitment.create!(profile: @organizer, created_by_profile: @organizer, assignee_profile: @organizer, domain: @domain, title: "Altro lavoro", kind: "work", status: "confirmed", starts_at: at(15), ends_at: at(16), blocks_calendar: true, pricing_type: "none", contribution_type: "unpaid")
      request = booking_request(requested_data_event: @day, starts_at: at(15), ends_at: at(16))

      assert_raises(ConfirmBookingRequest::Error) do
        ConfirmBookingRequest.new(commitment: request, confirmed_by_profile: @admin).call
      end

      assert_equal "requested", request.reload.status
      assert_nil request.data_event
      assert_empty @day.children.reload
    end

    test "confirmation fills capacity from the applied service and refuses another participant" do
      service = DataEvent.create!(
        title: "Servizio individuale", classification: "path", node_kind: "root",
        domain: @domain, created_by_profile: @organizer, responsible_profile: @organizer,
        service_definition: true, maximum_participants: 1,
        operator_roles: [{ "role" => "professional", "profile_id" => @organizer.id }]
      )
      session = DataEvent.create!(
        title: "Sessione", classification: "path", node_kind: "session", parent: @day,
        domain: @domain, created_by_profile: @organizer, responsible_profile: @organizer,
        service_data_event: service, starts_at: at(17), ends_at: at(18), status: "proposed"
      )
      first = booking_request(requested_data_event: session, starts_at: at(17), ends_at: at(18))

      ConfirmBookingRequest.new(commitment: first, confirmed_by_profile: @admin).call

      assert_equal "full", session.reload.registration_status
      assert_equal 1, session.confirmed_participants_count
      assert_equal 0, session.remaining_participant_places

      other_user = User.create!(email_address: "second-participant@example.com", password: "password123", password_confirmation: "password123")
      other_profile = other_user.create_profile!(display_name: "Secondo partecipante")
      second = DataCommitment.create!(profile: other_profile, created_by_profile: other_profile, domain: @domain, requested_data_event: session, title: "Seconda richiesta", kind: "academy", status: "requested", starts_at: at(17), ends_at: at(18), blocks_calendar: false, participation_role: "participant", pricing_type: "none", contribution_type: "unpaid")

      error = assert_raises(ConfirmBookingRequest::Error) do
        ConfirmBookingRequest.new(commitment: second, confirmed_by_profile: @admin).call
      end
      assert_equal "La sessione ha raggiunto la capienza massima.", error.message
      assert_equal "requested", second.reload.status
      assert_nil second.data_event
    end

    test "operator commitments and pending requests do not consume participant capacity" do
      session = DataEvent.create!(title: "Gruppo", classification: "path", node_kind: "session", parent: @day, domain: @domain, created_by_profile: @organizer, responsible_profile: @organizer, starts_at: at(17), ends_at: at(18), maximum_participants: 2, status: "confirmed")
      DataCommitment.create!(profile: @organizer, created_by_profile: @organizer, assignee_profile: @organizer, domain: @domain, data_event: session, title: "Conduzione", kind: "work", status: "confirmed", starts_at: at(17), ends_at: at(18), participation_role: "professional", pricing_type: "none", contribution_type: "unpaid")
      booking_request(requested_data_event: session, starts_at: at(17), ends_at: at(18))

      assert_equal 0, session.confirmed_participants_count
      assert_equal 2, session.remaining_participant_places
      assert_not session.participant_capacity_full?
    end

    test "cancelling the only participant closes an individual generated session and its operator commitment" do
      request = booking_request(requested_data_event: @day, starts_at: at(15), ends_at: at(16))
      result = ConfirmBookingRequest.new(commitment: request, confirmed_by_profile: @admin).call

      session = CancelConfirmedBooking.new(
        commitment: request,
        cancelled_by_profile: @admin,
        reason: "Impossibilità del partecipante"
      ).call

      assert_equal "cancelled", request.reload.status
      assert_not request.blocks_calendar?
      assert_equal "Impossibilità del partecipante", request.metadata.dig("cancellation", "reason")
      assert_equal @admin.id, request.metadata.dig("cancellation", "cancelled_by_profile_id")
      assert_equal "cancelled", session.reload.status
      assert_equal "closed", session.registration_status
      assert_not session.bookable?
      organizer_commitment = result.fetch(:organizer_commitment).reload
      assert_equal "cancelled", organizer_commitment.status
      assert_not organizer_commitment.blocks_calendar?
    end

    test "cancelling a participant in a group session reopens capacity without cancelling the session or operator" do
      session = DataEvent.create!(title: "Gruppo", classification: "path", node_kind: "session", parent: @day, domain: @domain, created_by_profile: @organizer, responsible_profile: @organizer, starts_at: at(17), ends_at: at(18), maximum_participants: 1, status: "confirmed", registration_status: "full")
      request = booking_request(requested_data_event: session, data_event: session, starts_at: at(17), ends_at: at(18), status: "confirmed", blocks_calendar: true)
      operator = DataCommitment.create!(profile: @organizer, created_by_profile: @admin, assignee_profile: @organizer, domain: @domain, data_event: session, title: "Conduzione", kind: "work", status: "confirmed", starts_at: at(17), ends_at: at(18), blocks_calendar: true, participation_role: "professional", pricing_type: "none", contribution_type: "unpaid")

      CancelConfirmedBooking.new(commitment: request, cancelled_by_profile: @admin).call

      assert_equal "cancelled", request.reload.status
      assert_equal "confirmed", session.reload.status
      assert_equal "open", session.registration_status
      assert_equal 1, session.remaining_participant_places
      assert_equal "confirmed", operator.reload.status
      assert operator.blocks_calendar?
    end

    private

      def booking_request(**attributes)
        DataCommitment.create!({
          profile: @participant, created_by_profile: @participant, domain: @domain,
          title: "Richiesta", kind: "academy", status: "requested", blocks_calendar: false,
          participation_role: "participant", pricing_type: "none", contribution_type: "unpaid"
        }.merge(attributes))
      end

      def at(hour)
        Time.zone.local(2026, 9, 8, hour)
      end
  end
end
