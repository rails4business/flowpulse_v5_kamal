module Brands
  module Impegno
    class HomeController < ApplicationController
      layout "landing"
      allow_unauthenticated_access

      AREAS = %w[agenda user professional places contacts].freeze
      VIEWS = {
        "agenda" => %w[agenda],
        "user" => %w[practices recurring],
        "professional" => %w[offering exchange reports],
        "places" => [],
        "contacts" => []
      }.freeze
      OFFERING_TABS = %w[services paths classes courses events].freeze
      EXPERIENCE_TABS = %w[habits paths classes courses events].freeze
      AGENDA_PERIODS = %w[upcoming past].freeze
      PROFESSIONAL_AGENDA_FILTERS = %w[all events booking_slots].freeze

      def index
        return unless authenticated?

        @impegno_brand = params[:brand].presence_in(%w[impegno posturacorretta generaimpresa personale]) || "impegno"
        @impegno_domains = available_impegno_domains
        @impegno_professional_access = Current.user.professional_user?
        requested_area = params[:area].presence_in(AREAS) || "agenda"
        @impegno_area = requested_area == "professional" && !@impegno_professional_access ? "user" : requested_area
        requested_view = params[:view] == "programs" ? "practices" : params[:view]
        @impegno_area = "agenda" if %w[user professional].include?(@impegno_area) && requested_view == "agenda"
        @impegno_view = requested_view.presence_in(VIEWS.fetch(@impegno_area)) || VIEWS.fetch(@impegno_area).first
        @impegno_period = @impegno_view == "agenda" ? params[:period].presence_in(AGENDA_PERIODS) : nil
        @impegno_agenda_filter = @impegno_area == "agenda" && @impegno_professional_access ? params[:agenda_filter].presence_in(PROFESSIONAL_AGENDA_FILTERS) || "all" : nil
        @impegno_tab = if @impegno_area == "professional" && @impegno_view == "offering"
          params[:tab].presence_in(OFFERING_TABS) || "services"
        elsif @impegno_area == "user" && @impegno_view == "practices"
          params[:tab].presence_in(EXPERIENCE_TABS) || "habits"
        else
          params[:tab].to_s.presence
        end
        @workspace_date = parse_workspace_date
        @workspace_src = workspace_src
      end

      private

        def parse_workspace_date
          Date.iso8601(params[:date])
        rescue Date::Error, TypeError
          Date.current
        end

        def workspace_src
          return impegno_contacts_path(workspace: "1") if @impegno_area == "contacts"
          return impegno_places_path(workspace: "1") if @impegno_area == "places"
          return unless @impegno_area == "agenda" && @impegno_view == "agenda"

          options = {
            workspace: "1",
            date: params[:date].presence,
            period: @impegno_period,
            area: @impegno_area,
            agenda_filter: @impegno_agenda_filter,
            default_brand: @impegno_brand,
            return_to: request.fullpath
          }.compact
          impegno_agenda_path(options)
        end

        def available_impegno_domains
          return Domain.active.where(primary: true).order(:hostname) if Current.user.superadmin_user?

          Current.user.profile.traveler_subscriptions.active.includes(:domain).map(&:domain).select(&:active?)
        end
    end
  end
end
