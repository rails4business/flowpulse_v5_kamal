module DataEvents
  class CancelConfirmedBooking
    class Error < StandardError; end

    def initialize(commitment:, cancelled_by_profile:, reason: nil)
      @commitment = commitment
      @cancelled_by_profile = cancelled_by_profile
      @reason = reason.to_s.strip.presence
    end

    def call
      DataCommitment.transaction do
        commitment.lock!
        raise Error, "La partecipazione non è confermata." unless commitment.status == "confirmed" && commitment.participation_role == "participant"

        session = commitment.data_event
        raise Error, "La partecipazione non è collegata a una sessione." unless session&.node_kind == "session"

        session.lock!
        audit = cancellation_audit
        commitment.update!(status: "cancelled", blocks_calendar: false, metadata: commitment.metadata.merge("cancellation" => audit))

        if individual_session_created_from_request?(session) && session.confirmed_participants_count.zero?
          cancel_session_and_operators!(session, audit)
        else
          session.refresh_registration_capacity!
        end

        session
      end
    rescue ActiveRecord::RecordInvalid => error
      raise Error, error.record.errors.full_messages.to_sentence
    end

    private

      attr_reader :commitment, :cancelled_by_profile, :reason

      def individual_session_created_from_request?(session)
        session.metadata["created_from_booking_request_id"].present?
      end

      def cancel_session_and_operators!(session, audit)
        session.data_commitments.where(status: "confirmed").where.not(participation_role: "participant").find_each do |operator_commitment|
          operator_commitment.update!(
            status: "cancelled",
            blocks_calendar: false,
            metadata: operator_commitment.metadata.merge("cancellation" => audit.merge("participant_commitment_id" => commitment.id))
          )
        end
        session.update!(status: "cancelled", registration_status: "closed", bookable: false)
      end

      def cancellation_audit
        {
          "reason" => reason,
          "cancelled_at" => Time.current.iso8601,
          "cancelled_by_profile_id" => cancelled_by_profile.id
        }.compact
      end
  end
end
