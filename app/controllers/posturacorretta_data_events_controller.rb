class PosturacorrettaDataEventsController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :require_authentication, only: :create_booking
  before_action :set_data_event, only: %i[show create_booking]

  def show
    return head :not_found unless visible_event?(@data_event)

    @root_event = root_for(@data_event)
    @tree_event = @data_event.node_kind == "root" ? @data_event : @root_event
    @selected_session = @data_event if @data_event.node_kind == "session"
    @booking_request = latest_booking_request
    @active_booking_request = active_booking_request
    @booking_time_proposals = booking_time_proposals(@data_event) if @data_event.node_kind == "day" && @data_event.bookable?
  end

  def create_booking
    return head :not_found unless visible_event?(@data_event)
    return redirect_to(posturacorretta_data_event_path(@data_event), alert: "Questo appuntamento non è prenotabile.") unless @data_event.bookable?
    if @data_event.node_kind == "session" && @data_event.participant_capacity_full?
      return redirect_to posturacorretta_data_event_path(@data_event), alert: "Questo appuntamento è completo."
    end

    existing = active_booking_request
    return redirect_to(posturacorretta_data_event_path(@data_event), notice: "La richiesta è già stata inviata.") if existing

    interval = requested_interval(@data_event)
    return redirect_to(posturacorretta_data_event_path(@data_event), alert: "Seleziona un orario ancora disponibile.") unless interval

    starts_at, ends_at, all_day = interval
    DataCommitment.create!(
      profile: current_profile,
      created_by_profile: current_profile,
      domain: @data_event.domain,
      requested_data_event: @data_event,
      title: "Richiesta · #{@data_event.title}",
      description: @data_event.booking_notes,
      kind: "academy",
      status: "requested",
      starts_at: starts_at,
      ends_at: ends_at,
      all_day: all_day,
      blocks_calendar: false,
      participation_role: "participant",
      pricing_type: "none",
      contribution_type: "unpaid",
      location_name: @data_event.effective_place&.name,
      location_address: @data_event.effective_place&.address,
      agreement_snapshot: booking_snapshot(@data_event),
      metadata: {
        "request_source" => "posturacorretta_data_event",
        "data_event_root_id" => root_for(@data_event).id
      }
    )

    redirect_to posturacorretta_data_event_path(@data_event), notice: "Richiesta inviata. Riceverai la conferma del superadmin."
  end

  private

    def set_data_event
      @data_event = DataEvent.includes(:domain, :place, :responsible_profile, children: [
        :domain, :place, :responsible_profile, { children: [:domain, :place, :responsible_profile, :children] }
      ]).find(params[:id])
    end

    def visible_event?(event)
      return true if Current.user&.superadmin_user?

      event.visibility == "public" && event.published_at.present? && event.status != "draft"
    end

    def root_for(event)
      current = event
      current = current.parent while current.parent
      current
    end

    def booking_requests_for_current_profile
      return unless Current.user&.profile

      Current.user.profile.data_commitments
        .where(requested_data_event: @data_event)
        .order(created_at: :desc)
    end

    def latest_booking_request
      booking_requests_for_current_profile&.first
    end

    def active_booking_request
      requests = booking_requests_for_current_profile
      requests.where.not(status: "cancelled").first if requests
    end

    def requested_interval(event)
      if event.node_kind == "day"
        selected_start = params[:requested_starts_at].to_s
        proposal = booking_time_proposals(event).find { |interval| interval.begin.iso8601 == selected_start }
        return [proposal.begin, proposal.end, false] if proposal

        return
      end

      return [event.starts_at, event.ends_at, event.all_day?] if event.starts_at

      date = event.active_from || root_for(event).active_from
      raise ActiveRecord::RecordInvalid, event unless date

      [Time.zone.local(date.year, date.month, date.day), nil, true]
    end

    def booking_time_proposals(event)
      duration = event.effective_duration_minutes
      DataEvents::BookingTimeProposal.new(day: event, duration_minutes: duration).call
    end

    def booking_snapshot(event)
      service = event.effective_service_data_event
      price_cents = event.effective_price_cents

      {
        "service_data_event_id" => service&.id,
        "service_title" => service&.title,
        "duration_minutes" => event.effective_duration_minutes,
        "price_cents" => price_cents,
        "currency" => (event.effective_currency if price_cents.present?)
      }.compact
    end
end
