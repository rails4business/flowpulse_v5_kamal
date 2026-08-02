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

        get impegno_url(brand: "impegno", area: "user", view: "agenda", date: "2026-08-02")

        assert_response :success
        assert_select "select[name=brand] option[selected][value=impegno]", text: "1impegno"
        assert_select "select[name=area] option[selected][value=user]", text: "Utente"
        assert_select "select[name=area] option[value=professional]", count: 1
        assert_select "a[aria-current=page]", text: "Agenda"
        assert_select "a[href*='view=practices']", text: "Esperienze"
        assert_select "a", text: "Ricorrenze"
        assert_select "nav[aria-label='Navigazione 1impegno']", count: 1
        assert_select "button[data-modal-dialog-id-value='start-commitment-dialog'][data-action='modal#open']", text: /Registra/
        assert_select "button[data-modal-dialog-id-value='new-commitment-dialog'][data-action='modal#open']", text: /Nuovo impegno/
        assert_select "turbo-frame#impegno_workspace[src]", count: 1 do |frames|
          assert_includes frames.first["src"], impegno_agenda_path
          assert_includes frames.first["src"], "workspace=1"
          assert_includes frames.first["src"], "date=2026-08-02"
        end

        get impegno_agenda_url(workspace: "1", date: "2026-08-02")
        assert_response :success
        assert_select "dialog#new-commitment-dialog form[action='#{data_commitments_path}'] input[name='data_commitment[title]']", count: 1
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
        assert_select "select[name=brand] option[selected][value=posturacorretta]", text: "PosturaCorretta"
        assert_select "nav[aria-label='Navigazione principale PosturaCorretta']", count: 1
        assert_select "turbo-frame#impegno_workspace[src*='brand_scope=posturacorretta']", count: 1
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
        assert_select "select[name=area] option[value=professional]", count: 0
        assert_select "a[aria-current=page]", text: "Esperienze"
        assert_select "nav[aria-label='Tipi di esperienza'] a", text: "Eventi"
        assert_select "h1", text: "Routine"
      end

      test "keeps professional workspace state in the URL and renders a placeholder" do
        user = User.create!(
          email_address: "impegno-professional@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user.create_profile!(display_name: "Professional User", username: "professional_user")
        creator_assignment = RoleAssignment.create!(profile: user.profile, role: :creator_of_worlds)
        RoleAssignment.create!(profile: user.profile, role: :professional, parent: creator_assignment)
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(area: "professional", view: "offering", tab: "events")

        assert_response :success
        assert_select "a[aria-current=page]", text: "Offerta"
        assert_select "nav[aria-label='Tipi di offerta professionale']" do
          assert_select "a", text: "Prestazioni"
          assert_select "a", text: "Percorsi"
          assert_select "a", text: "Classi"
          assert_select "a", text: "Corsi"
          assert_select "a[aria-current=page]", text: "Eventi"
        end
        assert_select "turbo-frame#impegno_workspace:not([src])", count: 1
        assert_select "h1", text: "Eventi"
      end

      test "does not expose the professional workspace without the professional role" do
        user = User.create!(
          email_address: "impegno-user-only@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        user.create_profile!(display_name: "User Only", username: "user_only")
        post session_url, params: { email_address: user.email_address, password: "password123" }

        get impegno_url(area: "professional", view: "offering")

        assert_response :success
        assert_select "select[name=area] option[selected][value=user]", text: "Utente"
        assert_select "select[name=area] option[value=professional]", count: 0
        assert_select "a[aria-current=page]", text: "Agenda"
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
