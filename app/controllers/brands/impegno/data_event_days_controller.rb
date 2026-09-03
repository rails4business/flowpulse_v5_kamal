module Brands
  module Impegno
    class DataEventDaysController < ApplicationController
      layout "landing"

      before_action :require_superadmin
      before_action :set_root_event
      before_action :set_day, only: %i[edit update]

      def new
        @day = @root_event.children.build(node_kind: "day", bookable: false)
      end

      def create
        @day = @root_event.children.build(day_params)
        apply_inherited_attributes

        if @day.save
          redirect_to edit_impegno_data_event_path(@root_event), notice: "Fascia aggiunta."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        @day.assign_attributes(day_params)
        apply_inherited_attributes

        if @day.save
          redirect_to edit_impegno_data_event_path(@root_event), notice: "Fascia aggiornata."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

        def require_superadmin
          head :not_found unless Current.user&.superadmin_user?
        end

        def set_root_event
          @root_event = DataEvent.roots.find(params[:data_event_id])
        end

      def set_day
        @day = @root_event.children.where(node_kind: "day").find(params[:id])
        @sessions = @day.children.where(node_kind: "session").chronological
      end

        def day_params
          params.require(:data_event).permit(:title, :starts_at, :ends_at, :bookable)
        end

        def apply_inherited_attributes
          @day.assign_attributes(
            node_kind: "day",
            domain: @root_event.domain,
            classification: @root_event.classification,
            created_by_profile: (@day.created_by_profile || current_profile),
            responsible_profile: @root_event.responsible_profile,
            status: (@root_event.draft? ? "draft" : "proposed"),
            visibility: @root_event.visibility,
            published_at: @root_event.published_at,
            registration_status: (@day.bookable? ? "open" : "pending"),
            registration_mode: (@day.bookable? ? "required" : "none"),
            booking_mode: (@day.bookable? ? "individual_request" : "none"),
            all_day: false
          )
        end
    end
  end
end
