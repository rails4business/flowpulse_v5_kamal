require "test_helper"

module Brands
  module Impegno
    class DataEventsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = User.create!(email_address: "events-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        @admin.create_profile!(display_name: "Events Admin", username: "events_admin")
        @operator = User.create!(email_address: "events-operator@example.com", password: "password123", password_confirmation: "password123")
        @operator.create_profile!(display_name: "Operatore Eventi", username: "events_operator")
        @domain = Domain.create!(hostname: "events-admin.example", locale: "it", target_controller: "landing", target_action: "flowpulse", active: true, primary: true, site_title: "Eventi Test")
      end

      test "superadmin creates a private root draft" do
        sign_in(@admin)

        get new_impegno_data_event_url(domain_id: @domain.id)
        assert_response :success
        assert_select "h1", text: "Nuovo evento"
        assert_select "select[name='data_event[domain_id]'] option[selected][value='#{@domain.id}']"

        assert_difference("DataEvent.roots.count", 1) do
          post impegno_data_events_url, params: { data_event: {
            domain_id: @domain.id,
            title: "Percorso pilota",
            description: "Prima edizione",
            classification: "course",
            responsible_profile_id: @operator.profile.id,
            status: "draft",
            visibility: "private"
          } }
        end

        event = DataEvent.order(:created_at).last
        assert_redirected_to impegno_data_events_url(domain_id: @domain.id)
        assert_equal "root", event.node_kind
        assert_equal @admin.profile, event.created_by_profile
        assert_equal @operator.profile, event.responsible_profile
        assert_nil event.published_at
      end

      test "event domain filter collapses www alias into one brand choice" do
        www_domain = Domain.create!(hostname: "www.events-admin.example", locale: "it", target_controller: "landing", target_action: "flowpulse", active: true, primary: false, site_title: "Eventi Test")
        canonical_event = create_root
        alias_event = DataEvent.create!(title: "Evento su alias", classification: "event", node_kind: "root", domain: www_domain, created_by_profile: @admin.profile, status: "draft", visibility: "private")
        sign_in(@admin)

        get impegno_data_events_url

        assert_response :success
        assert_select "select[name=domain_id] option", text: "Eventi Test", count: 1
        assert_includes response.body, canonical_event.title
        assert_includes response.body, alias_event.title

        get impegno_data_events_url(domain_id: @domain.id)
        assert_response :success
        assert_includes response.body, canonical_event.title
        assert_includes response.body, alias_event.title
      end

      test "superadmin edits and publishes a non draft root" do
        event = create_root
        sign_in(@admin)

        patch impegno_data_event_url(event), params: { data_event: {
          domain_id: @domain.id,
          title: "Evento pubblicato",
          classification: "event",
          responsible_profile_id: @operator.profile.id,
          status: "confirmed",
          visibility: "public"
        } }

        assert_redirected_to impegno_data_events_url(domain_id: @domain.id)
        event.reload
        assert_equal "Evento pubblicato", event.title
        assert_equal "confirmed", event.status
        assert_equal "public", event.visibility
        assert event.published_at.present?
      end

      test "draft cannot be public" do
        sign_in(@admin)

        assert_no_difference("DataEvent.count") do
          post impegno_data_events_url, params: { data_event: {
            domain_id: @domain.id,
            title: "Bozza esposta",
            classification: "event",
            status: "draft",
            visibility: "public"
          } }
        end

        assert_response :unprocessable_entity
        assert_select "p", text: "Controlla i dati inseriti"
      end

      test "event with a concrete interval creates root day and bookable session" do
        sign_in(@admin)

        assert_difference("DataEvent.count", 3) do
          post impegno_data_events_url, params: {
            session_starts_at: "2026-09-20T15:00", session_ends_at: "2026-09-20T16:30",
            data_event: { domain_id: @domain.id, title: "Evento concreto", classification: "event", responsible_profile_id: @operator.profile.id, status: "confirmed", visibility: "public" }
          }
        end

        root = DataEvent.roots.find_by!(title: "Evento concreto")
        day = root.children.find_by!(node_kind: "day")
        session = day.children.find_by!(node_kind: "session")
        assert_equal Time.zone.parse("2026-09-20 15:00"), day.starts_at
        assert_equal day.starts_at, session.starts_at
        assert_equal day.ends_at, session.ends_at
        assert session.bookable?
        assert_equal "session", session.booking_mode
        assert_equal "public", session.visibility
        assert session.published_at.present?
      end

      test "operational view keeps event structure and linked commitments together" do
        root = create_root
        day = root.children.create!(title: "Pomeriggio", classification: "event", node_kind: "day", domain: @domain, created_by_profile: @admin.profile, starts_at: Time.zone.parse("2026-09-20 14:00"), ends_at: Time.zone.parse("2026-09-20 18:00"), status: "proposed", visibility: "private")
        session = day.children.create!(title: "Sessione pratica", classification: "event", node_kind: "session", domain: @domain, created_by_profile: @admin.profile, responsible_profile: @operator.profile, starts_at: Time.zone.parse("2026-09-20 15:00"), ends_at: Time.zone.parse("2026-09-20 16:00"), status: "proposed", visibility: "private", bookable: true, booking_mode: "session", registration_mode: "required", registration_status: "open")
        participant = User.create!(email_address: "event-view-participant@example.com", password: "password123", password_confirmation: "password123").create_profile!(display_name: "Partecipante Vista")
        DataCommitment.create!(profile: participant, created_by_profile: participant, assignee_profile: participant, domain: @domain, data_event: session, title: "Partecipazione", kind: "academy", status: "confirmed", starts_at: session.starts_at, ends_at: session.ends_at, blocks_calendar: false, participation_role: "participant", pricing_type: "none", contribution_type: "unpaid")
        DataCommitment.create!(profile: @operator.profile, created_by_profile: @admin.profile, assignee_profile: @operator.profile, domain: @domain, data_event: session, title: "Conduzione", kind: "work", status: "confirmed", starts_at: session.starts_at, ends_at: session.ends_at, blocks_calendar: false, participation_role: "professional", pricing_type: "none", contribution_type: "unpaid")
        sign_in(@admin)

        get impegno_data_event_url(root)

        assert_response :success
        assert_select "h1", text: "Evento interno"
        assert_select "h2", text: "Struttura e persone"
        assert_select "[role=tree] [data-node-kind=session]", text: /Sessione pratica/
        assert_select "ul[aria-label='Persone e ruoli della sessione'] li", text: /Partecipante Vista.*participant/
        assert_select "ul[aria-label='Persone e ruoli della sessione'] li", text: /Operatore Eventi.*professional/
        assert_select "a[href='#{impegno_agenda_path}']", text: "Apri agenda 1impegno"
      end

      test "non superadmin cannot access or mutate event management" do
        event = create_root
        sign_in(@operator)

        get impegno_data_events_url
        assert_response :not_found
        get edit_impegno_data_event_url(event)
        assert_response :not_found
        patch impegno_data_event_url(event), params: { data_event: { title: "Non autorizzato" } }
        assert_response :not_found
        assert_equal "Evento interno", event.reload.title
      end

      private

        def create_root
          DataEvent.create!(title: "Evento interno", classification: "event", node_kind: "root", domain: @domain, created_by_profile: @admin.profile, status: "draft", visibility: "private")
        end

        def sign_in(user)
          post session_url, params: { email_address: user.email_address, password: "password123" }
        end
    end
  end
end
