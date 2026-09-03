require "test_helper"

class PosturacorrettaDataEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "public-data-event@example.com", password: "password123", password_confirmation: "password123")
    @profile = @user.create_profile!(display_name: "Mark Postura")
    @domain = Domain.create!(hostname: "public-data-event.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
    @root = DataEvent.create!(
      title: "PosturaCorretta in un mese", classification: "course", node_kind: "root",
      domain: @domain, created_by_profile: @profile, responsible_profile: @profile,
      status: "organizing", visibility: "public", published_at: Time.current
    )
    @day = DataEvent.create!(
      title: "Martedì 8 settembre 2026", classification: "course", node_kind: "day", parent: @root,
      domain: @domain, created_by_profile: @profile, status: "proposed", visibility: "public",
      published_at: Time.current, starts_at: Time.zone.parse("2026-09-08 00:00"), all_day: true
    )
    @session = DataEvent.create!(
      title: "Lezione pratica", classification: "course", node_kind: "session", parent: @day,
      domain: @domain, created_by_profile: @profile, responsible_profile: @profile,
      status: "proposed", visibility: "public", published_at: Time.current,
      starts_at: Time.zone.parse("2026-09-08 15:00"), ends_at: Time.zone.parse("2026-09-08 16:00"),
      registration_status: "open", registration_mode: "required", bookable: true, booking_mode: "session"
    )
  end

  test "shows a published session with its complete tree" do
    get posturacorretta_data_event_path(@session)

    assert_response :success
    assert_select "h1", text: "Lezione pratica"
    assert_select "#programma-evento-title", text: "Programma e orari"
    assert_select "a", text: "PosturaCorretta in un mese"
    assert_select "span.text-slate-500", text: "September 08, 2026"
    assert_select "a", text: "Lezione pratica"
    assert_select "a[href='#{new_session_path(return_to: posturacorretta_data_event_path(@session))}']", text: "Accedi per prenotare"
    assert_select "p", text: "Condizioni da definire"
  end

  test "shows free and paid booking conditions" do
    @session.update!(price_cents: 0)
    get posturacorretta_data_event_path(@session)
    assert_select "p", text: "Gratuito"

    @session.update!(price_cents: 2_500, currency: "EUR")
    get posturacorretta_data_event_path(@session)
    assert_select "p", text: "25,00 EUR"
  end

  test "does not expose a private event" do
    @session.update!(visibility: "private", published_at: nil)

    get posturacorretta_data_event_path(@session)

    assert_response :not_found
  end

  test "event catalog exposes the complete show for an imported yaml event" do
    catalog_domain = Domain.create!(hostname: "posturacorretta.org", target_controller: "brands/posturacorretta", target_action: "index", locale: "it")
    imported = DataEvent.create!(
      title: "Evento in piscina · Carpenedolo", classification: "event", node_kind: "root",
      domain: catalog_domain, created_by_profile: @profile, responsible_profile: @profile,
      status: "organizing", visibility: "public", published_at: Time.current,
      metadata: { "source" => "yaml", "yaml_event_slug" => "2026-08-15-evento-in-piscina-carpenedolo" }
    )

    get posturacorretta_eventi_path

    assert_response :success
    assert_includes response.body, posturacorretta_data_event_path(imported)
    assert_includes response.body, "Apri programma completo"
  end

  test "authenticated user requests a booking once without blocking the calendar" do
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    assert_difference("DataCommitment.count", 1) do
      post book_posturacorretta_data_event_path(@session)
    end
    assert_redirected_to posturacorretta_data_event_path(@session)

    commitment = DataCommitment.order(:created_at).last
    assert_equal @session, commitment.requested_data_event
    assert_nil commitment.data_event
    assert_equal "requested", commitment.status
    assert_equal "participant", commitment.participation_role
    assert_not commitment.blocks_calendar?
    assert_equal @session.starts_at, commitment.starts_at
    assert_equal @session.ends_at, commitment.ends_at
    assert_equal({}, commitment.agreement_snapshot)

    assert_no_difference("DataCommitment.count") do
      post book_posturacorretta_data_event_path(@session)
    end


    get posturacorretta_data_event_path(@session)
    assert_select "p", text: "Richiesta inviata"
    assert_select "p", text: "In attesa di conferma"
    assert_select "form[action='#{withdraw_impegno_request_path(commitment)}'] button", text: "Ritira richiesta"

    commitment.update!(status: "confirmed")
    get posturacorretta_data_event_path(@session)
    assert_select "p", text: "Partecipazione confermata"
    assert_select "p", text: "Il posto è confermato"
    assert_select "form[action='#{book_posturacorretta_data_event_path(@session)}']", count: 0

    commitment.update!(status: "cancelled", blocks_calendar: false)
    get posturacorretta_data_event_path(@session)
    assert_select "p", text: "Richiesta annullata"
    assert_select "p", text: "Questa richiesta non è più attiva"
    assert_select "form[action='#{book_posturacorretta_data_event_path(@session)}']", count: 1
  end

  test "booking snapshots the effective service conditions" do
    service = DataEvent.create!(
      title: "Lezione individuale", classification: "course", node_kind: "root",
      domain: @domain, created_by_profile: @profile, responsible_profile: @profile,
      service_definition: true, duration_minutes: 60, price_cents: 3_500, currency: "EUR"
    )
    @session.update!(service_data_event: service)
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    post book_posturacorretta_data_event_path(@session)

    snapshot = DataCommitment.order(:created_at).last.agreement_snapshot
    assert_equal service.id, snapshot["service_data_event_id"]
    assert_equal "Lezione individuale", snapshot["service_title"]
    assert_equal 60, snapshot["duration_minutes"]
    assert_equal 3_500, snapshot["price_cents"]
    assert_equal "EUR", snapshot["currency"]
  end

  test "booking requires authentication" do
    post book_posturacorretta_data_event_path(@session)

    assert_response :redirect
    assert_equal new_session_path, URI.parse(response.location).path
    assert_equal 0, DataCommitment.where(requested_data_event: @session).count
  end

  test "user chooses a proposed time inside a bookable day window" do
    day = DataEvent.create!(
      title: "Disponibilità pomeridiana", classification: "course", node_kind: "day", parent: @root,
      domain: @domain, created_by_profile: @profile, responsible_profile: @profile,
      status: "proposed", visibility: "public", published_at: Time.current,
      starts_at: Time.zone.parse("2026-09-09 15:00"), ends_at: Time.zone.parse("2026-09-09 18:00"),
      duration_minutes: 60, registration_status: "open", registration_mode: "required",
      bookable: true, booking_mode: "individual_request"
    )
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    get posturacorretta_data_event_path(day)

    assert_response :success
    assert_select "input[type=radio][name=requested_starts_at][value='2026-09-09T15:00:00+02:00'][checked]", count: 1

    assert_difference("DataCommitment.count", 1) do
      post book_posturacorretta_data_event_path(day), params: { requested_starts_at: Time.zone.parse("2026-09-09 15:00").iso8601 }
    end

    commitment = DataCommitment.order(:created_at).last
    assert_equal day, commitment.requested_data_event
    assert_equal Time.zone.parse("2026-09-09 15:00"), commitment.starts_at
    assert_equal Time.zone.parse("2026-09-09 16:00"), commitment.ends_at
    assert_equal "requested", commitment.status
    assert_not commitment.blocks_calendar?
  end

  test "server rejects a time that is not among the current proposals" do
    day = DataEvent.create!(
      title: "Disponibilità serale", classification: "course", node_kind: "day", parent: @root,
      domain: @domain, created_by_profile: @profile, responsible_profile: @profile,
      status: "proposed", visibility: "public", published_at: Time.current,
      starts_at: Time.zone.parse("2026-09-10 20:00"), ends_at: Time.zone.parse("2026-09-10 22:00"),
      duration_minutes: 60, registration_status: "open", registration_mode: "required",
      bookable: true, booking_mode: "individual_request"
    )
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    assert_no_difference("DataCommitment.count") do
      post book_posturacorretta_data_event_path(day), params: { requested_starts_at: Time.zone.parse("2026-09-10 19:00").iso8601 }
    end

    assert_redirected_to posturacorretta_data_event_path(day)
    assert_equal "Seleziona un orario ancora disponibile.", flash[:alert]
  end

  test "full session shows capacity and refuses new booking requests" do
    @session.update!(maximum_participants: 1, registration_status: "open")
    participant_user = User.create!(email_address: "confirmed-capacity@example.com", password: "password123", password_confirmation: "password123")
    participant = participant_user.create_profile!(display_name: "Già confermato")
    DataCommitment.create!(profile: participant, created_by_profile: participant, assignee_profile: participant, domain: @domain, data_event: @session, title: "Partecipazione", kind: "academy", status: "confirmed", starts_at: @session.starts_at, ends_at: @session.ends_at, blocks_calendar: true, participation_role: "participant", pricing_type: "none", contribution_type: "unpaid")
    @session.refresh_registration_capacity!
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    get posturacorretta_data_event_path(@session)

    assert_response :success
    assert_select "span", text: "Completo"
    assert_select "dt", text: "Capienza"
    assert_select "dt", text: "Confermati"
    assert_select "dt", text: "Disponibili"
    assert_select "dd", text: "0"
    assert_select "p", text: "Appuntamento completo"
    assert_select "form[action='#{book_posturacorretta_data_event_path(@session)}']", count: 0

    assert_no_difference("DataCommitment.count") do
      post book_posturacorretta_data_event_path(@session)
    end
    assert_equal "Questo appuntamento è completo.", flash[:alert]
  end
end
