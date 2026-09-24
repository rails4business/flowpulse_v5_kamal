module Brands
  module Impegno
    class ExperienceSlotsController < ExperienceBaseController
      before_action :set_context
      before_action :ensure_experience_access!

      def create
        slots = @data_session ? @data_session.data_slots : @experience.data_slots
        slot = slots.build(slot_params.merge(
          data_experience: @experience,
          position: slots.maximum(:position).to_i + 1
        ))
        if slot.save
          respond_with_workbench(notice: "Slot aggiunto.")
        else
          respond_with_workbench(alert: slot.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def update
        if @data_slot.update(slot_params)
          respond_with_workbench(notice: "Slot aggiornato.")
        else
          respond_with_workbench(alert: @data_slot.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def destroy
        @data_slot.destroy!
        respond_with_workbench(notice: "Slot rimosso.")
      rescue ActiveRecord::RecordNotDestroyed
        respond_with_workbench(alert: "Rimuovi prima i DataCommitment di questo Slot.", status: :unprocessable_entity)
      end

      private

        def set_context
          if action_name == "create"
            params[:session_id].present? ? set_experience_from_session : set_experience
          else
            set_experience_from_slot
          end
        end

        def slot_params
          params.require(:data_slot).permit(:title, :starts_at, :ends_at, :position)
        end
    end
  end
end
