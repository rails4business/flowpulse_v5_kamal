module Brands
  module Impegno
    class ExperienceBaseController < ApplicationController
      layout "landing"
      before_action -> { require_permission!(:superadmin) }

      private

        def set_experience
          @experience = DataExperience.find(params[:experience_id] || params[:id])
        end

        def set_experience_from_session
          @data_session = DataSession.find(params[:session_id] || params[:id])
          @experience = @data_session.data_experience
        end

        def set_experience_from_slot
          @data_slot = DataSlot.find(params[:slot_id] || params[:id])
          @data_session = @data_slot.data_session
          @experience = @data_slot.data_experience
        end

        def ensure_experience_access!
          return if Current.user&.superadmin_user?

          redirect_to impegno_path, alert: "Durante il pilota le Esperienze sono riservate al superadmin."
        end

        def workbench_sessions
          @experience.data_sessions.includes(data_slots: :data_commitments)
            .order(Arel.sql("starts_at ASC NULLS LAST"), :position, :created_at)
        end

        def prepare_workbench_state
          @services = Service.active.includes(:node).order("nodes.title", :title)
          @brand_processes = BrandProcess.includes(:node).where(status: %w[draft active]).order("nodes.title", :title)
          @professional_calendars = ProfessionalCalendar.active.includes(:context_node, :professional_node).to_a
            .sort_by { |calendar| [calendar.professional_node.title, calendar.context_node.title, calendar.title] }
          @sessions = workbench_sessions
          @all_slots = @experience.data_slots.includes(:data_session, data_commitments: :profile)
            .order(Arel.sql("starts_at ASC NULLS LAST"), :position, :created_at).to_a
          @all_commitments = @experience.data_commitments.includes(:profile)
            .order(Arel.sql("starts_at ASC NULLS LAST"), :position, :created_at).to_a

          planned_slots = @all_slots.select { |slot| slot.starts_at.present? }
          @scheduled_slots_by_day = planned_slots.group_by { |slot| slot.starts_at.to_date }
          scheduled_session_ids = planned_slots.filter_map(&:data_session_id).uniq
          @scheduled_sessions_by_day = @sessions.select { |data_session| data_session.starts_at.present? }
            .group_by { |data_session| data_session.starts_at.to_date }
          @unplanned_sessions = @sessions.select { |data_session| data_session.starts_at.blank? }
          @unplanned_slots = @all_slots.select { |slot| slot.starts_at.blank? }
          @scheduled_direct_commitments_by_day = @experience.data_commitments
            .where(data_session_id: nil, data_slot_id: nil).where.not(starts_at: nil).includes(:profile)
            .order(:starts_at, :position).to_a.group_by { |commitment| commitment.starts_at.to_date }
          @unplanned_commitments = @all_commitments.select { |commitment| commitment.starts_at.blank? }
        end

        def respond_with_workbench(notice: nil, alert: nil, status: :ok)
          prepare_workbench_state
          flash.now[:notice] = notice if notice.present?
          flash.now[:alert] = alert if alert.present?

          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                "experience_workbench",
                partial: "brands/impegno/experiences/workbench",
                locals: { experience: @experience, sessions: @sessions }
              ), status: status
            end
            format.html { redirect_to impegno_experience_path(@experience), notice: notice, alert: alert }
          end
        end
    end
  end
end
