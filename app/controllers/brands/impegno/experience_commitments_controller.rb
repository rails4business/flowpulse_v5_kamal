module Brands
  module Impegno
    class ExperienceCommitmentsController < ExperienceBaseController
      before_action :set_context
      before_action :ensure_experience_access!

      def create
        owner = @data_slot || @data_session || @experience
        position = owner.data_commitments.maximum(:position).to_i + 1
        commitment = owner.data_commitments.build(commitment_params.merge(commitment_defaults).merge(position: position))
        if commitment.save
          respond_with_workbench(notice: "DataCommitment aggiunto.")
        else
          respond_with_workbench(alert: commitment.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def update
        if @commitment.update(commitment_params)
          respond_with_workbench(notice: "DataCommitment aggiornato.")
        else
          respond_with_workbench(alert: @commitment.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def destroy
        @commitment.destroy!
        respond_with_workbench(notice: "DataCommitment rimosso.")
      end

      private

        def set_context
          if params[:slot_id].present?
            set_experience_from_slot
          elsif params[:session_id].present?
            set_experience_from_session
          else
            set_experience
          end
          return if action_name == "create"

          @commitment = if @data_slot
            @data_slot.data_commitments.find(params[:id])
          elsif @data_session
            @data_session.data_commitments.find(params[:id])
          else
            @experience.data_commitments.find(params[:id])
          end
        end

        def commitment_params
          params.require(:data_commitment).permit(:title, :status, :starts_at, :ends_at, :position)
        end

        def commitment_defaults
          profile = current_profile
          domain = current_domain || Domain.active.order(:id).first
          raise ActiveRecord::RecordNotFound, "Nessun dominio configurato" if domain.blank?

          {
            profile: profile,
            created_by_profile: profile,
            domain: domain,
            data_experience: @experience,
            data_session: @data_session,
            data_slot: @data_slot,
            kind: "work",
            status: "planned",
            pricing_type: "none",
            contribution_type: "unpaid",
            blocks_calendar: false
          }
        end
    end
  end
end
