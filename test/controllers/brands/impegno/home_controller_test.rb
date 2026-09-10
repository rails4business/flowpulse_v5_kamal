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
        assert_select "select[name=area]", count: 0
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Agenda"
        assert_select "nav[aria-label='Sezioni di Impegno'] a", text: "Luoghi"
        assert_select "nav[aria-label='Sezioni di Impegno'] a", text: "Contatti"
        assert_select "section[aria-label='Contesti dell’agenda'], section[aria-label=\"Contesti dell'agenda\"]", text: /La mia agenda/
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

        get impegno_url(brand: "impegno", area: "agenda", view: "agenda", view_mode: "structure")
        assert_response :success
        assert_select "nav[aria-label='Vista agenda'] a[aria-current=page][style*='background-color:#4f46e5']", text: "Struttura & Calendari"
        assert_select "turbo-frame#impegno_workspace[src*='view_mode=structure']", count: 1

        get impegno_agenda_url(workspace: "1", view_mode: "structure")
        assert_response :success
        assert_select "#oneimpegno", count: 1
        assert_select "script#oneimpegno-data", count: 1
        assert_select "#oneimpegno button[data-view='tree']", text: "Struttura"
        assert_select "#oneimpegno button[data-view='week']", text: "Calendari"
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

      test "normalizes the legacy programs view into the single agenda" do
        user = User.create!(
          email_address: "impegno-practices@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user.create_profile!(display_name: "Practices User", username: "practices_user")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(area: "user", view: "programs")

        assert_response :success
        assert_select "select[name=area]", count: 0
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Agenda"
        assert_select "nav[aria-label='Tipi di esperienza']", count: 0
        assert_select "section[aria-label='Contesti dell’agenda'], section[aria-label=\"Contesti dell'agenda\"]", text: /La mia agenda/
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
        assert_select "select[name=area]", count: 0
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Agenda"
        assert_select "span", text: "Professionista", count: 0
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
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Agenda"
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
        assert_select "select[name=area]", count: 0
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Agenda"
        assert_select "span", text: "Insegnante", count: 0
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
        assert_select "select[name=area]", count: 0
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Agenda"
        assert_select "span", text: "Insegnante", count: 0
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
        assert_select "select[name=area]", count: 0
        assert_select "select[name=brand][aria-label='Sito dei ruoli operativi']", count: 1

        get impegno_url(brand: "impegno", area: "agenda")

        assert_response :success
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Agenda"
        assert_select "select[name=brand] option[value=posturacorretta]", count: 1
        assert_select "select[name=brand] option[value=generaimpresa]", count: 1

        get impegno_url(brand: "posturacorretta", area: "agenda")

        assert_response :success
        assert_select "form input[type=hidden][name=area][value=agenda] + input[type=hidden][name=view][value=agenda] + select[name=brand][aria-label='Sito dei ruoli operativi']" do
          assert_select "option[value=posturacorretta]", count: 1
          assert_select "option[value=generaimpresa]", count: 1
          assert_select "option", text: "Non iscritto", count: 0
        end
      end

      test "loads shared places and contacts as Impegno workspace areas" do
        user = User.create!(email_address: "impegno-shared-areas@example.com", password: "password123", password_confirmation: "password123")
        user.create_profile!(display_name: "Shared Areas", username: "shared_areas")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(area: "places")

        assert_response :success
        assert_select "nav[aria-label='Sezioni di Impegno'] a[aria-current=page]", text: "Luoghi"
        assert_select "turbo-frame#impegno_workspace[src*='impegno/places']", count: 1
      end
    end
  end
end
