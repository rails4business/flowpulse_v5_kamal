module Brands
  module Impegno
    class RequestsController < ApplicationController
      before_action :require_superadmin, only: %i[confirm reject cancel_confirmation]
      before_action :require_authentication, only: :withdraw

      def withdraw
        commitment = current_profile.data_commitments.where(status: "requested").find(params[:id])
        commitment.update!(
          status: "cancelled",
          blocks_calendar: false,
          metadata: commitment.metadata.merge(
            "withdrawal" => {
              "withdrawn_at" => Time.current.iso8601,
              "withdrawn_by_profile_id" => current_profile.id
            }
          )
        )

        redirect_to posturacorretta_data_event_path(commitment.requested_data_event), notice: "Richiesta ritirata."
      end

      def confirm
        commitment = DataCommitment.where(status: "requested").find(params[:id])
        DataEvents::ConfirmBookingRequest.new(commitment:, confirmed_by_profile: current_profile).call

        redirect_to requests_path(commitment), notice: "Richiesta confermata e aggiunta ai calendari."
      rescue DataEvents::ConfirmBookingRequest::Error => error
        redirect_to requests_path(commitment), alert: "Richiesta non confermata: #{error.message}"
      end

      def reject
        commitment = DataCommitment.where(status: "requested").find(params[:id])
        rejection = {
          "reason" => params[:rejection_reason].to_s.strip.presence,
          "rejected_at" => Time.current.iso8601,
          "rejected_by_profile_id" => current_profile.id
        }.compact

        commitment.update!(
          status: "cancelled",
          blocks_calendar: false,
          metadata: commitment.metadata.merge("rejection" => rejection)
        )

        redirect_to requests_path, notice: "Richiesta rifiutata. Lo storico è stato conservato."
      end

      def cancel_confirmation
        commitment = DataCommitment.where(status: "confirmed", participation_role: "participant").find(params[:id])
        DataEvents::CancelConfirmedBooking.new(
          commitment:,
          cancelled_by_profile: current_profile,
          reason: params[:cancellation_reason]
        ).call

        redirect_to requests_path, notice: "Partecipazione annullata e posto liberato."
      rescue DataEvents::CancelConfirmedBooking::Error => error
        redirect_to requests_path(commitment), alert: "Partecipazione non annullata: #{error.message}"
      end

      private

        def require_superadmin
          head :not_found unless Current.user&.superadmin_user?
        end

        def requests_path(commitment = nil)
          impegno_path(
            brand: params[:brand].presence_in(%w[impegno posturacorretta percorso_integrato generaimpresa personale]),
            area: "domain_roles",
            view: "requests",
            request_id: commitment&.id
          )
        end
    end
  end
end
