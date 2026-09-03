module Brands
  module Impegno
    class DataEventSessionsController < ApplicationController
      layout "landing"

      before_action :require_superadmin
      before_action :set_hierarchy
      before_action :set_session, only: %i[edit update]

      def new
        @session = @day.children.build(node_kind: "session", bookable: true, starts_at: @day.starts_at, ends_at: @day.ends_at)
      end

      def create
        @session = @day.children.build(session_params)
        apply_inherited_attributes
        if @session.save
          redirect_to edit_impegno_data_event_day_path(@root_event, @day), notice: "Sessione aggiunta."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        @session.assign_attributes(session_params)
        apply_inherited_attributes
        if @session.save
          redirect_to edit_impegno_data_event_day_path(@root_event, @day), notice: "Sessione aggiornata."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

        def require_superadmin
          head :not_found unless Current.user&.superadmin_user?
        end

        def set_hierarchy
          @root_event = DataEvent.roots.find(params[:data_event_id])
          @day = @root_event.children.where(node_kind: "day").find(params[:day_id])
        end

        def set_session
          @session = @day.children.where(node_kind: "session").find(params[:id])
        end

        def session_params
          params.require(:data_event).permit(:title, :starts_at, :ends_at, :maximum_participants, :bookable)
        end

        def apply_inherited_attributes
          @session.assign_attributes(
            node_kind: "session", domain: @root_event.domain,
            classification: @root_event.classification,
            created_by_profile: (@session.created_by_profile || current_profile),
            responsible_profile: @root_event.responsible_profile,
            status: (@root_event.draft? ? "draft" : "proposed"),
            visibility: @root_event.visibility, published_at: @root_event.published_at,
            registration_status: (@session.bookable? ? "open" : "pending"),
            registration_mode: (@session.bookable? ? "required" : "none"),
            booking_mode: (@session.bookable? ? "session" : "none"), all_day: false
          )
        end
    end
  end
end
