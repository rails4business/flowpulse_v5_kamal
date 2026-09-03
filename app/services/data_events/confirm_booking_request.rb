module DataEvents
  class ConfirmBookingRequest
    class Error < StandardError; end

    def initialize(commitment:, confirmed_by_profile:)
      @commitment = commitment
      @confirmed_by_profile = confirmed_by_profile
    end

    def call
      DataCommitment.transaction do
        commitment.lock!
        raise Error, "La richiesta è già stata elaborata." unless commitment.status == "requested"

        requested_event = commitment.requested_data_event
        raise Error, "La richiesta non è collegata a un evento." unless requested_event

        requested_event.lock!
        session = resolve_session(requested_event)
        session.lock!
        raise Error, "La sessione ha raggiunto la capienza massima." if session.participant_capacity_full?

        organizer = session.organizer_profile
        organizer_role = session.organizer_participation_role
        raise Error, "L'evento non ha un organizzatore operativo completo." unless organizer && organizer_role.present?

        confirm_participant!(session)
        organizer_commitment = confirm_organizer!(session, organizer, organizer_role)
        session.refresh_registration_capacity!

        { session:, participant_commitment: commitment, organizer_commitment: }
      end
    rescue ActiveRecord::RecordInvalid => error
      raise Error, error.record.errors.full_messages.to_sentence
    end

    private

      attr_reader :commitment, :confirmed_by_profile

      def resolve_session(event)
        if event.node_kind == "session"
          raise Error, "La sessione non è più confermabile." if %w[completed cancelled].include?(event.status)

          event.update!(status: "confirmed") unless event.status == "confirmed"
          return event
        end
        raise Error, "La richiesta deve riferirsi a una sessione o a una fascia giornaliera." unless event.node_kind == "day"
        raise Error, "La richiesta non contiene un intervallo completo." unless commitment.starts_at && commitment.ends_at
        unless commitment.starts_at >= event.starts_at && commitment.ends_at <= event.ends_at
          raise Error, "L'orario richiesto non rientra nella fascia disponibile."
        end

        event.children.create!(
          title: "Appuntamento · #{root_for(event).title}",
          classification: event.classification,
          node_kind: "session",
          domain: event.effective_domain,
          created_by_profile: confirmed_by_profile,
          responsible_profile: event.organizer_profile,
          place: event.effective_place,
          service_data_event: service_reference_for(event),
          starts_at: commitment.starts_at,
          ends_at: commitment.ends_at,
          position: event.children.maximum(:position).to_i + 1,
          status: "confirmed",
          visibility: event.visibility,
          published_at: event.published_at,
          registration_status: "open",
          registration_mode: "required",
          bookable: false,
          booking_mode: "session",
          operator_roles: event.effective_operator_roles,
          metadata: { "created_from_booking_request_id" => commitment.id }
        )
      end

      def service_reference_for(event)
        service = event.effective_service_data_event
        service unless service == event
      end

      def confirm_participant!(session)
        participant_profile = commitment.assignee_profile || commitment.profile
        calendar_key = commitment.participant_contact ? "contact:#{commitment.participant_contact_id}" : "profile:#{participant_profile.id}"
        calendar_label = commitment.participant_contact&.name || participant_profile.display_name.presence || participant_profile.username
        agreement = commitment.agreement_snapshot

        commitment.update!(
          data_event: session,
          assignee_profile: (participant_profile unless commitment.participant_contact),
          starts_at: session.starts_at,
          ends_at: session.ends_at,
          all_day: false,
          status: "confirmed",
          blocks_calendar: true,
          participation_role: commitment.participation_role.presence || "participant",
          agreed_price_cents: agreement["price_cents"],
          agreed_currency: agreement["currency"],
          agreed_duration_minutes: agreement["duration_minutes"],
          calendar_key:,
          calendar_label:,
          location_name: session.effective_place&.name,
          location_address: session.effective_place&.address,
          metadata: commitment.metadata.merge("confirmation" => confirmation_audit(session))
        )
      end

      def confirm_organizer!(session, organizer, organizer_role)
        existing = DataCommitment
          .where(data_event: session, assignee_profile: organizer, participation_role: organizer_role)
          .where.not(status: "cancelled")
          .first
        return existing if existing

        DataCommitment.create!(
          profile: organizer,
          created_by_profile: confirmed_by_profile,
          assignee_profile: organizer,
          responsible_profile: organizer,
          domain: session.effective_domain,
          data_event: session,
          title: "#{organizer_role.humanize} · #{session.title}",
          kind: "work",
          status: "confirmed",
          starts_at: session.starts_at,
          ends_at: session.ends_at,
          blocks_calendar: true,
          participation_role: organizer_role,
          pricing_type: "none",
          contribution_type: "unpaid",
          calendar_key: "profile:#{organizer.id}",
          calendar_label: organizer.display_name.presence || organizer.username,
          location_name: session.effective_place&.name,
          location_address: session.effective_place&.address,
          metadata: { "confirmation" => confirmation_audit(session) }
        )
      end

      def confirmation_audit(session)
        {
          "confirmed_at" => Time.current.iso8601,
          "confirmed_by_profile_id" => confirmed_by_profile.id,
          "session_id" => session.id
        }
      end

      def root_for(event)
        current = event
        current = current.parent while current.parent
        current
      end
  end
end
