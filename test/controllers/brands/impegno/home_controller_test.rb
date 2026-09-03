require "test_helper"

module Brands
  module Impegno
    class HomeControllerTest < ActionDispatch::IntegrationTest
      test "renders the public Impegno brand page" do
        get impegno_url

        assert_response :success
        assert_select "h1", /Il tuo tempo/
        assert_select "a[href=?]", new_user_path(return_to: data_commitments_path), text: /Apri Impegno/
      end

      test "renders the authenticated Impegno workspace with the Agenda turbo frame" do
        user = User.create!(
          email_address: "impegno-workspace@example.com",
          password: "password123",
          password_confirmation: "password123",
          superadmin: true,
          active_role: :superadmin
        )
        user.create_profile!(display_name: "Workspace User", username: "workspace_user")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(brand: "impegno", area: "agenda", view: "agenda", date: "2026-08-02")

        assert_response :success
        assert_select "input[type=hidden][name=brand][value=impegno]", minimum: 1
        assert_select "select[name=brand]", count: 0
        assert_select "select[name=area] option[selected][value=agenda]", text: "Agenda"
        assert_select "select[name=area] option[value=professional]", count: 0
        assert_select "span", text: "Agenda"
        assert_select "a[href*='view=practices']", count: 0
        assert_select "nav[aria-label='Navigazione 1impegno']", count: 1
        assert_select "nav[aria-label='Navigazione 1impegno'] details[data-close-on-outside] summary.profile-menu-toggle[aria-label='Apri menu profilo']", count: 1
        assert_select "nav[aria-label='Navigazione 1impegno'] a[href='#{profile_path}']", text: "Profilo"
        assert_select "button[data-modal-dialog-id-value='start-commitment-dialog'][data-action='click->modal#open'][onclick*='start-commitment-dialog']", text: /Registra/
        assert_select "button[data-modal-dialog-id-value='new-commitment-dialog'][data-action='click->modal#open'][onclick*='new-commitment-dialog']", text: /Nuovo impegno/
        assert_select "nav[aria-label='Vista agenda'] a", text: "Settimana"
        assert_select "turbo-frame#impegno_workspace[src]", count: 1 do |frames|
          assert_includes frames.first["src"], impegno_agenda_path
          assert_includes frames.first["src"], "workspace=1"
          assert_includes frames.first["src"], "date=2026-08-02"
        end

        get impegno_agenda_url(workspace: "1", date: "2026-08-02")
        assert_response :success
        assert_select "dialog#new-commitment-dialog form[action='#{data_commitments_path}'] input[name='data_commitment[title]']", count: 1

        get impegno_url(brand: "impegno", area: "agenda", view: "agenda", view_mode: "weekplan")
        assert_response :success
        assert_select "nav[aria-label='Vista agenda'] a[aria-current=page][style*='background-color:#2563eb']", text: "Settimana"
        assert_select "turbo-frame#impegno_workspace[src*='view_mode=weekplan']", count: 1

        get impegno_url(brand: "impegno", area: "agenda", view: "agenda")
        assert_response :success
        assert_select "nav[aria-label='Vista agenda'] a[aria-current=page][style*='background-color:#0f172a']", text: "Elenco"
        assert_select "turbo-frame#impegno_workspace[src*='view_mode=weekplan']", count: 0
      end

      test "uses the same Impegno shell from PosturaCorretta with its brand preselected" do
        user = User.create!(
          email_address: "posturacorretta-impegno@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user.create_profile!(display_name: "Postura User", username: "postura_impegno_user")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get posturacorretta_impegno_url

        assert_response :success
        assert_select "input[type=hidden][name=brand][value=posturacorretta]", minimum: 1
        assert_select "select[name=brand]", count: 0
        assert_select "nav[aria-label='Navigazione principale PosturaCorretta']", count: 1
        assert_select "turbo-frame#impegno_workspace[src*='default_brand=posturacorretta']", count: 1
        assert_select "turbo-frame#impegno_workspace[src*='brand_scope=posturacorretta']", count: 0
      end

      test "shows the active timer bar in the Impegno shell" do
        user = User.create!(
          email_address: "impegno-active-timer@example.com",
          password: "password123",
          password_confirmation: "password123",
          superadmin: true,
          active_role: :superadmin
        )
        user.create_profile!(display_name: "Timer User", username: "timer_user")
        domain = Domain.create!(hostname: "timer-impegno.test", locale: "it", target_controller: "landing", target_action: "flowpulse", primary: true, active: true)
        commitment = Brands::Impegno::Commitment.create!(profile: user.profile, created_by_profile: user.profile, domain: domain, title: "Preparare il programma", description: "Sto organizzando l'evento.", kind: "work", status: "in_progress", starts_at: Time.current, actual_started_at: Time.current, pricing_type: "none", contribution_type: "unpaid")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url

        assert_response :success
        assert_select "aside[aria-label='Attività in corso']", text: /Sto organizzando l'evento/
        assert_select "button[commandfor='complete-commitment-#{commitment.id}']", text: /Concludi/
      end

      test "normalizes the legacy programs view concept to Esperienze" do
        user = User.create!(
          email_address: "impegno-practices@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user.create_profile!(display_name: "Practices User", username: "practices_user")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(area: "user", view: "programs")

        assert_response :success
        assert_select "select[name=area] option[value=domain_roles]", count: 0
        assert_select "a[aria-current=page]", text: "Esperienze"
        assert_select "nav[aria-label='Tipi di esperienza'] a", text: "Eventi"
        assert_select "h1", text: "Routine"
      end

      test "keeps operational roles private even for a professional" do
        user = User.create!(
          email_address: "impegno-professional@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user.create_profile!(display_name: "Professional User", username: "professional_user")
        domain = Domain.create!(hostname: "percorsointegrato.it", locale: "it", target_controller: "brands/percorso_integrato", target_action: "index", primary: true, active: true, settings: { operational_roles: ["professional", "tutor"] })
        user.profile.domain_memberships.create!(domain: domain)
        creator_assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
        RoleAssignment.create!(profile: user.profile, role: :professional, context: domain, parent: creator_assignment)
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(brand: "percorso_integrato", area: "domain_roles", role: "professional", view: "offering", tab: "events")

        assert_response :success
        assert_select "select[name=area] option[selected][value=user]", text: "Utente"
        assert_select "select[name=area] option[value=domain_roles]", count: 0
      end

      test "redirects the legacy professional area to domain roles" do
        user = User.create!(email_address: "impegno-legacy-professional@example.com", password: "password123", password_confirmation: "password123")
        user.create_profile!(display_name: "Legacy Professional", username: "legacy_professional")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(brand: "posturacorretta", area: "professional", view: "offering")

        assert_redirected_to impegno_url(brand: "posturacorretta", area: "domain_roles", view: "offering")
        assert_response :moved_permanently
      end

      test "loads the professional agenda with event and booking-slot filters" do
        user = User.create!(email_address: "impegno-professional-agenda@example.com", password: "password123", password_confirmation: "password123")
        user.create_profile!(display_name: "Professional Agenda", username: "professional_agenda")
        creator_assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
        RoleAssignment.create!(profile: user.profile, role: :professional, parent: creator_assignment)
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(area: "agenda", view: "agenda", agenda_filter: "events", date: "2026-08-02")

        assert_response :success
        assert_select "span", text: "Agenda"
        assert_select "turbo-frame#impegno_workspace[src*='area=agenda'][src*='agenda_filter=events']", count: 1

        get impegno_agenda_url(workspace: "1", area: "agenda", agenda_filter: "events")
        assert_response :success
        assert_select "nav[aria-label='Filtro agenda professionista'] a[aria-current=page]", text: "I miei eventi"
        assert_select "nav[aria-label='Filtro agenda professionista'] a", text: "Slot prenotazione"
      end

      test "does not expose the professional workspace without the professional role" do
        user = User.create!(
          email_address: "impegno-user-only@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user.create_profile!(display_name: "User Only", username: "user_only")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        domain = Domain.create!(hostname: "posturacorretta.org", locale: "it", target_controller: "brands/posturacorretta", target_action: "home", primary: true, active: true, settings: { operational_roles: ["teacher", "tutor", "segreteria_clienti"] })
        user.profile.domain_memberships.create!(domain: domain)

        get impegno_url(brand: "posturacorretta", area: "domain_roles", role: "teacher")

        assert_response :success
        assert_select "select[name=area] option[selected][value=user]", text: "Utente"
        assert_select "select[name=area] option[value=domain_roles]", count: 0
        assert_select "a[aria-current=page]", text: "Esperienze"
      end

      test "does not expose operational roles to a teacher" do
        user = User.create!(email_address: "posturacorretta-teacher@example.com", password: "password123", password_confirmation: "password123")
        user.create_profile!(display_name: "Postura Teacher", username: "postura_teacher")
        domain = Domain.create!(hostname: "posturacorretta.org", locale: "it", target_controller: "brands/posturacorretta", target_action: "home", primary: true, active: true, settings: { operational_roles: ["teacher", "tutor", "segreteria_clienti"] })
        user.profile.domain_memberships.create!(domain: domain)
        creator_assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
        RoleAssignment.create!(profile: user.profile, role: :teacher, context: domain, parent: creator_assignment)
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(brand: "posturacorretta", area: "domain_roles", role: "teacher")

        assert_response :success
        assert_select "select[name=area] option[selected][value=user]", text: "Utente"
        assert_select "select[name=area] option[value=domain_roles]", count: 0
        assert_select "h1", text: "Routine"
      end

      test "offers only active domain memberships in the site selector" do
        user = User.create!(email_address: "impegno-memberships@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        user.create_profile!(display_name: "Membership User", username: "membership_user")
        postura = Domain.create!(hostname: "posturacorretta.org", locale: "it", target_controller: "brands/posturacorretta", target_action: "home", primary: true, active: true, site_title: "PosturaCorretta", settings: { operational_roles: ["teacher"] })
        genera = Domain.create!(hostname: "generaimpresa.it", locale: "it", target_controller: "landing", target_action: "flowpulse", primary: true, active: true, site_title: "GeneraImpresa")
        Domain.create!(hostname: "unrelated.test", locale: "it", target_controller: "landing", target_action: "flowpulse", primary: true, active: true, site_title: "Non iscritto")
        user.profile.domain_memberships.create!(domain: postura)
        user.profile.domain_memberships.create!(domain: genera)
        creator_assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
        RoleAssignment.create!(profile: user.profile, role: :teacher, context: postura, parent: creator_assignment)
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(brand: "posturacorretta")

        assert_response :success
        assert_select "select[name=brand]", count: 0
        assert_select "select[name=area] option[value=domain_roles]", text: "Ruoli operativi"

        get impegno_url(brand: "impegno", area: "domain_roles")

        assert_response :success
        assert_select "select[name=area] option[selected][value=domain_roles]", text: "Ruoli operativi"
        assert_select "select[name=brand] option[selected][value=posturacorretta]", count: 1

        get impegno_url(brand: "posturacorretta", area: "domain_roles")

        assert_response :success
        assert_select "form input[type=hidden][name=area][value=domain_roles] + select[name=brand][aria-label='Sito dei ruoli operativi']" do
          assert_select "option[value=posturacorretta]", count: 1
          assert_select "option[value=generaimpresa]", count: 1
          assert_select "option", text: "Non iscritto", count: 0
        end
      end

      test "shows pending participation requests only for the selected domain" do
        user = User.create!(email_address: "impegno-requests-admin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        user.create_profile!(display_name: "Requests Admin", username: "requests_admin")
        participant = User.create!(email_address: "participant@example.com", password: "password123", password_confirmation: "password123")
        participant.create_profile!(display_name: "Mario Partecipante", username: "mario_participant")
        domain = Domain.create!(hostname: "posturacorretta.org", locale: "it", target_controller: "brands/posturacorretta", target_action: "home", primary: true, active: true, settings: { operational_roles: ["teacher"] })
        other_domain = Domain.create!(hostname: "generaimpresa.it", locale: "it", target_controller: "landing", target_action: "flowpulse", primary: true, active: true)
        event = DataEvent.create!(title: "Lezione di prova", classification: "class", node_kind: "root", status: "confirmed", visibility: "public", published_at: Time.current, registration_status: "open", registration_mode: "required", booking_mode: "parent", service_scope: "private", position: 0, domain: domain, created_by_profile: user.profile)
        other_event = DataEvent.create!(title: "Richiesta altro dominio", classification: "event", node_kind: "root", status: "confirmed", visibility: "public", published_at: Time.current, registration_status: "open", registration_mode: "required", booking_mode: "parent", service_scope: "private", position: 0, domain: other_domain, created_by_profile: user.profile)
        represented_contact = Brands::Impegno::Contact.create!(profile: participant.profile, name: "Maria Assistita", kind: "person", email: "maria@example.com", phone: "+39 333 1234567")
        request = DataCommitment.create!(profile: participant.profile, created_by_profile: participant.profile, participant_contact: represented_contact, domain: domain, requested_data_event: event, title: "Richiesta · Lezione di prova", description: "Preferisce il pomeriggio", kind: "academy", status: "requested", starts_at: 1.day.from_now, blocks_calendar: false, pricing_type: "none", contribution_type: "unpaid", agreement_snapshot: { "duration_minutes" => 60, "price_cents" => 0, "currency" => "EUR" })
        confirmed_request = DataCommitment.create!(profile: participant.profile, created_by_profile: participant.profile, domain: domain, requested_data_event: event, title: "Partecipazione confermata", kind: "academy", status: "confirmed", starts_at: 3.days.from_now, blocks_calendar: false, participation_role: "participant", pricing_type: "none", contribution_type: "unpaid", metadata: { "confirmation" => { "confirmed_at" => 1.hour.from_now.iso8601, "confirmed_by_profile_id" => user.profile.id } })
        cancelled_request = DataCommitment.create!(profile: participant.profile, created_by_profile: participant.profile, domain: domain, requested_data_event: event, title: "Richiesta annullata", kind: "academy", status: "cancelled", starts_at: 4.days.from_now, blocks_calendar: false, participation_role: "participant", pricing_type: "none", contribution_type: "unpaid", metadata: { "rejection" => { "rejected_at" => 2.hours.from_now.iso8601, "rejected_by_profile_id" => user.profile.id, "reason" => "Orario non disponibile" } })
        DataCommitment.create!(profile: participant.profile, created_by_profile: participant.profile, domain: other_domain, requested_data_event: other_event, title: "Richiesta · altro dominio", kind: "academy", status: "requested", starts_at: 2.days.from_now, blocks_calendar: false, pricing_type: "none", contribution_type: "unpaid")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests")

        assert_response :success
        assert_select "select[name=area] option[selected][value=domain_roles]", text: "Ruoli operativi"
        assert_select "a[aria-current=page]", text: "Richieste"
        assert_select "h1", text: "Richieste di partecipazione"
        assert_select "nav[aria-label='Filtra richieste per stato']" do
          assert_select "a[aria-current=page]", text: "In attesa (1)"
          assert_select "a", text: "Confermate (1)"
          assert_select "a", text: "Annullate (1)"
          assert_select "a", text: "Tutte (3)"
        end
        assert_select "ul[aria-label='Richieste filtrate'] li", count: 1 do
          assert_select "p", text: "Maria Assistita"
          assert_select "p", text: "Lezione di prova"
          assert_select "a[href*='request_id=#{request.id}']", text: "Apri richiesta"
          assert_select "p", text: "Richiesta altro dominio", count: 0
        end

        get impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests", request_status: "confirmed", request_id: confirmed_request.id)
        assert_response :success
        assert_select "a[aria-current=page]", text: "Confermate (1)"
        assert_select "a[href*='request_id=#{confirmed_request.id}']", text: "Apri richiesta"
        assert_select "a[href*='request_id=#{request.id}']", count: 0
        assert_select "section[aria-labelledby='request-history-title']" do
          assert_select "p", text: "Richiesta inviata"
          assert_select "p", text: "Partecipazione confermata"
          assert_select "p", text: /Requests Admin/
        end

        get impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests", request_status: "cancelled", request_id: cancelled_request.id)
        assert_response :success
        assert_select "a[aria-current=page]", text: "Annullate (1)"
        assert_select "a[href*='request_id=#{cancelled_request.id}']", text: "Apri richiesta"
        assert_select "section[aria-labelledby='request-history-title']" do
          assert_select "p", text: "Richiesta rifiutata"
          assert_select "p", text: "Orario non disponibile"
        end

        get impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests", request_status: "confirmed", request_id: request.id)
        assert_response :success
        assert_select "article[aria-labelledby='request-detail-title']", count: 0

        get impegno_url(brand: "posturacorretta", area: "domain_roles", view: "requests", request_id: request.id)

        assert_response :success
        assert_select "article[aria-labelledby='request-detail-title']" do
          assert_select "h2", text: "Maria Assistita"
          assert_select "dd", text: "Contatto senza account"
          assert_select "dd", text: "Mario Partecipante"
          assert_select "dd", text: "maria@example.com"
          assert_select "p", text: "Preferisce il pomeriggio"
          assert_select "a[href='#{posturacorretta_data_event_path(event)}']", text: "Vedi evento completo"
          assert_select "section[aria-labelledby='request-history-title'] p", text: "Richiesta inviata"
        end
      end

      test "loads shared places and contacts as Impegno workspace areas" do
        user = User.create!(email_address: "impegno-shared-areas@example.com", password: "password123", password_confirmation: "password123")
        user.create_profile!(display_name: "Shared Areas", username: "shared_areas")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(area: "places")

        assert_response :success
        assert_select "select[name=area] option[selected][value=places]", text: "Luoghi"
        assert_select "turbo-frame#impegno_workspace[src*='impegno/places']", count: 1
      end
    end
  end
end
