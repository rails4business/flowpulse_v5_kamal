require "test_helper"

module Workspace
  class DataCommitmentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(
        email_address: "workspace-commitments@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      @profile = @user.create_profile!(display_name: "Mark Workspace", username: "mark_workspace")
      @domain = Domain.create!(hostname: "workspace-commitments.test", locale: "it", primary: true, active: true)
      @recipient = @profile.impegno_contacts.create!(name: "Fornitore esempio", kind: "person")
      @commitment = @profile.data_commitments.create!(
        created_by_profile: @profile,
        participant_contact: @recipient,
        domain: @domain,
        title: "Pagare il servizio fotografico",
        kind: "purchase",
        status: "planned",
        starts_at: nil,
        blocks_calendar: false,
        pricing_type: "fixed",
        total_price: 250,
        contribution_type: "paid"
      )

      other_user = User.create!(
        email_address: "other-workspace-commitments@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      other_profile = other_user.create_profile!(display_name: "Altro profilo", username: "other_workspace")
      other_profile.data_commitments.create!(
        created_by_profile: other_profile,
        domain: @domain,
        title: "Impegno riservato ad altro profilo",
        kind: "work",
        status: "planned",
        starts_at: 1.day.from_now,
        blocks_calendar: true,
        pricing_type: "none",
        contribution_type: "unpaid"
      )
    end

    test "requires authentication" do
      get workspace_data_commitments_url

      assert_redirected_to new_session_path(return_to: "/data_commitments")
    end

    test "shows only the current profile commitments in the shared dashboard" do
      sign_in

      get workspace_data_commitments_url

      assert_response :success
      assert_select "body[data-layout='workspace']"
      assert_select "aside[data-dashboard-sidebar]", count: 0
      assert_select "header[aria-label='Testata dashboard condivisa']"
      assert_select "nav[aria-label='Aree della dashboard condivisa']", text: /1impegno/
      assert_select "h2", "Da fare"
      assert_select "nav[aria-label='Sezioni di 1impegno'] a", text: /Agenda/
      assert_select "nav[aria-label='Sezioni di 1impegno'] a", text: /Settimana/
      assert_select "#data-commitment-#{@commitment.id}", text: /Pagare il servizio fotografico/
      assert_select "#data-commitment-#{@commitment.id}", text: /Fornitore esempio/
      assert_select "body", { text: /Impegno riservato ad altro profilo/, count: 0 }
      assert_select "footer[aria-label='Versioni collegate']"
      assert_select "footer[aria-label='Versioni collegate'] summary", text: /Versioni collegate/
      assert_select "a[href=?]", workspace_data_commitments_path, text: /Ufficiale/
    end

    test "the todo list excludes completed commitments" do
      completed = @profile.data_commitments.create!(
        created_by_profile: @profile,
        domain: @domain,
        title: "Pagamento già completato",
        kind: "purchase",
        status: "completed",
        starts_at: 1.day.ago,
        blocks_calendar: false,
        pricing_type: "none",
        contribution_type: "unpaid"
      )
      sign_in

      get workspace_data_commitments_url

      assert_response :success
      assert_select "#data-commitment-#{completed.id}", count: 0
    end

    test "agenda and week show only personal calendar data" do
      personal_session = DataSession.create!(
        title: "Workshop personale",
        starts_at: Time.zone.parse("2026-10-23 16:00"),
        ends_at: Time.zone.parse("2026-10-23 19:00"),
        created_by_profile: @profile,
        status: "confirmed",
        visibility: "private"
      )
      other_profile = Profile.find_by!(username: "other_workspace")
      other_session = DataSession.create!(
        title: "Sessione di un altro profilo",
        starts_at: Time.zone.parse("2026-10-23 17:00"),
        created_by_profile: other_profile,
        status: "confirmed",
        visibility: "private"
      )
      sign_in

      get workspace_data_commitments_agenda_url(date: "2026-10-23")

      assert_response :success
      assert_select "h2", "Agenda"
      assert_select "h2", "Il programma della settimana"
      assert_select "nav[aria-label='Navigazione temporale agenda'] a[href=?]", workspace_data_commitments_agenda_path(scope: "past"), text: "Passati"
      assert_select "nav[aria-label='Navigazione temporale agenda'] input[type='date'][name='date'][value='2026-10-23']"
      assert_select "nav[aria-label='Navigazione temporale agenda'] a[href=?]", workspace_data_commitments_agenda_path(scope: "future"), text: "Futuri"
      assert_select "nav[aria-label='Navigazione temporale agenda']", { text: /Oggi/, count: 0 }
      assert_select ".home__programma__text__table ul"
      assert_select ".home__programma__text__table", text: /16:00 – 19:00 – Workshop personale/
      assert_select ".home__programma__text__table", { text: /Sessione/, count: 0 }
      assert_select "aside[data-dashboard-sidebar]", count: 0
      assert_select "#data-session-#{personal_session.id}", text: /Workshop personale/
      assert_select "#data-session-#{other_session.id}", count: 0

      get workspace_data_commitments_agenda_url(scope: "past")
      assert_response :success
      assert_select "nav[aria-label='Navigazione temporale agenda'] a[aria-pressed='true']", text: "Passati"
      assert_select "body", { text: /Workshop personale/, count: 0 }

      get workspace_data_commitments_agenda_url(scope: "future")
      assert_response :success
      assert_select "nav[aria-label='Navigazione temporale agenda'] a[aria-pressed='true']", text: "Futuri"
      assert_select "#data-session-#{personal_session.id}", text: /Workshop personale/

      get workspace_data_commitments_week_url(date: "2026-10-23")

      assert_response :success
      assert_select "h2", "Settimana"
      assert_select "aside[data-dashboard-sidebar]", count: 0
      assert_select "#week-data-session-#{personal_session.id}", text: /Workshop personale/
      assert_select "#week-data-session-#{other_session.id}", count: 0
    end

    private

      def sign_in
        post session_url, params: { email_address: @user.email_address, password: "password123" }
      end
  end
end
