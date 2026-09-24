module Brands
  module Impegno
    class ExperienceSessionsController < ExperienceBaseController
      before_action :set_context
      before_action :ensure_experience_access!

      def create
        data_session = @experience.data_sessions.build(session_params.merge(position: @experience.data_sessions.maximum(:position).to_i + 1))
        if data_session.save
          respond_with_workbench(notice: "Session aggiunta.")
        else
          respond_with_workbench(alert: data_session.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def update
        if @data_session.update(session_params)
          respond_with_workbench(notice: "Session aggiornata.")
        else
          respond_with_workbench(alert: @data_session.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      def destroy
        @data_session.destroy!
        respond_with_workbench(notice: "Session rimossa.")
      rescue ActiveRecord::RecordNotDestroyed
        respond_with_workbench(alert: "Rimuovi prima gli Slot contenuti nella Session.", status: :unprocessable_entity)
      end

      private

        def set_context
          if action_name == "create"
            set_experience
          else
            set_experience_from_session
          end
        end

        def session_params
          params.require(:data_session).permit(
            :title, :starts_at, :ends_at, :position, :professional_calendar_id, :service_id, :visibility
          )
        end
    end
  end
end
