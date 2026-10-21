module Workspace
  class DataCommitmentsController < ApplicationController
    layout "workspace"
    dashboard_section :data_commitments

    OPEN_STATUSES = %w[draft requested planned confirmed in_progress].freeze

    def index
      @data_commitments = personal_commitments
        .where(status: OPEN_STATUSES)
        .order(Arel.sql("data_commitments.starts_at ASC NULLS LAST, data_commitments.created_at DESC"))
        .limit(250)
    end

    def agenda
      set_period
      @agenda_scope = params[:scope].presence_in(%w[past future])
      case @agenda_scope
      when "past"
        load_calendar_data(time_range: ...Time.current, direction: :desc)
      when "future"
        load_calendar_data(time_range: Time.current.., direction: :asc)
      else
        load_calendar_data
      end
    end

    def week
      set_period
      load_calendar_data
    end

    private

      def personal_commitments
        commitment = Brands::Impegno::Commitment
        commitment
          .where(profile_id: current_profile.id)
          .or(commitment.where(assignee_profile_id: current_profile.id))
          .or(commitment.where(responsible_profile_id: current_profile.id))
          .distinct
          .includes(
            :assignee_profile,
            :created_by_profile,
            :participant_contact,
            :responsible_profile,
            :subject,
            :data_session,
            :data_slot,
            domain: :node,
            skill_product: [:reusable_skill, :node],
            data_experience: :node_process
          )
      end

      def set_period
        @selected_date = begin
          Date.iso8601(params[:date].to_s)
        rescue Date::Error
          Date.current
        end
        @week_start = @selected_date.beginning_of_week
        @week_end = @week_start.end_of_week
      end

      def load_calendar_data(time_range: nil, direction: :asc)
        range = time_range || (@week_start.beginning_of_day..@week_end.end_of_day)
        order_direction = direction == :desc ? :desc : :asc
        personal = personal_commitments
        @commitments = personal
          .where.not(status: "cancelled")
          .where(starts_at: range)
          .order(starts_at: order_direction, position: order_direction, id: order_direction)
          .limit(250)
          .to_a

        personal_ids = personal.except(:includes, :preload, :eager_load)
        linked_session_ids = personal_ids.where.not(data_session_id: nil).distinct.pluck(:data_session_id)
        linked_slot_ids = personal_ids.where.not(data_slot_id: nil).distinct.pluck(:data_slot_id)
        linked_session_ids.concat(DataSlot.where(id: linked_slot_ids).where.not(data_session_id: nil).pluck(:data_session_id))

        session = DataSession.where(starts_at: range)
        @data_sessions = session.where(id: linked_session_ids)
          .or(session.where(created_by_profile_id: current_profile.id))
        if current_profile.primary_node_id.present?
          calendar_ids = ProfessionalCalendar.where(professional_node_id: current_profile.primary_node_id).select(:id)
          @data_sessions = @data_sessions.or(session.where(professional_calendar_id: calendar_ids))
        end
        @data_sessions = @data_sessions
          .where.not(status: "cancelled")
          .includes(:professional_calendar, :data_experience, data_slots: :data_commitments)
          .distinct
          .order(starts_at: order_direction, position: order_direction, id: order_direction)
          .limit(250)
          .to_a

        visible_session_ids = @data_sessions.map(&:id)
        slot = DataSlot.where(starts_at: range)
        @standalone_slots = slot.where(id: linked_slot_ids)
          .or(slot.where(created_by_profile_id: current_profile.id))
          .where.not(data_session_id: visible_session_ids)
          .where.not(status: "cancelled")
          .includes(:data_experience, :data_commitments)
          .distinct
          .order(starts_at: order_direction, position: order_direction, id: order_direction)
          .limit(250)
          .to_a
      end
  end
end
