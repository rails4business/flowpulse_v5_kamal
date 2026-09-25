require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "Flowpulse navigation exposes projects professionals and changelog" do
    get flowpulse_url

    assert_response :success
    assert_select "nav[aria-label='Navigazione Flowpulse'] a[href='#{flowpulse_projects_path}']", text: "Progetti"
    assert_select "nav[aria-label='Navigazione Flowpulse'] a[href='#{flowpulse_professionals_path}']", text: "Professionisti"
    assert_select "nav[aria-label='Navigazione Flowpulse'] a[href='#{changelog_path}']", text: "Changelog"
    assert_select "footer a[href='https://github.com/rails4business/flowpulse_v5_kamal'][target='_blank']", text: /GitHub/
  end

  test "Flowpulse projects index renders public registry entries" do
    get flowpulse_projects_url

    assert_response :success
    assert_select "h1", text: "Progetti"
    assert_select "a[href='/posturacorretta']", text: /PosturaCorretta/
    assert_select "a[href='/impegno']", text: /1Impegno/
    assert_select "a[href='/rails4b']", text: /Rails4Business/
    assert_select "a[href='/cantachetipassa']", text: /Canta che ti passa/
  end

  test "Flowpulse professionals index has a safe YAML fallback" do
    host! "localhost"
    get flowpulse_professionals_url

    assert_response :success
    assert_select "h1", text: "Professionisti"
    assert_select "a[href='/markpostura']", text: /MarkPostura/
  end

  test "MarkPostura local route renders the editorial YAML home" do
    get markpostura_url

    assert_response :success
    assert_select "h1", text: "Tre progetti, per affrontare i cambiamenti."
    assert_select "#progetti a", count: 3
    assert_select "#ingresso li", count: 4
    assert_select "#progetti [data-language-card]", count: 3
    assert_select "#progetti", text: /Fisiologia/
    assert_select "#timeline iframe", count: 0
    assert_select "#timeline [data-timeline-deferred]"
    assert_select "#timeline button[data-timeline-trigger]", text: "Carica ora"
  end

  test "MarkPostura exposes its TimelineJS page" do
    get markpostura_timeline_url

    assert_response :success
    assert_select "h2", text: "Il percorso nel tempo"
    assert_select "iframe[src*='cdn.knightlab.com/libs/timeline3']"
    assert_includes response.body, "15u53Qb9xAY-6MeT_YC1Daevb8XTSeJGSPpg8Wyj9LuY"
  end

  test "MarkPostura exposes a dedicated shareable Week Plan" do
    get markpostura_weekplan_url(week: "2026-W38", spaces: "postura-gruppo,postura-app")

    assert_response :success
    assert_select "#weekplan"
    assert_select "button[data-space]", count: 5
    assert_select "dialog#wp-modal"
    assert_select "#mark-week-reminders-title", count: 0
    assert_select "#mark-private-program-title", count: 0
    assert_not_includes response.body, "Registrazione con Fabrizio"
    assert_includes response.body, "2026-W38"
    assert_includes response.body, "postura-gruppo,postura-app"
  end

  test "MarkPostura shows reminders and detailed program only to superadmin" do
    superadmin = User.create!(
      email_address: "mark-weekplan-superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    post session_url, params: { email_address: superadmin.email_address, password: "password123" }

    get markpostura_weekplan_url(week: "2026-W38")

    assert_response :success
    assert_select "#mark-week-reminders-title", text: "Promemoria da collocare"
    assert_select "#mark-private-program-title", text: "Programma operativo dettagliato"
    assert_includes response.body, "Registrazione con Fabrizio"
    assert_includes response.body, "Dirette YouTube"
    assert_includes response.body, "PosturaCorretta"
    assert_includes response.body, "Il Giardino del Corpo"
    assert_includes response.body, "Tempo di produzione e scrittura"
  end

  test "MarkPostura publishes group lessons but not private writing time" do
    get markpostura_weekplan_url(week: "2026-W39")

    assert_response :success
    assert_includes response.body, "Lezione di gruppo · Inizia con PosturaCorretta"
    assert_includes response.body, "Pubblicazione corso · Inizia con PosturaCorretta"
    assert_not_includes response.body, "Preparazione · Inizia con PosturaCorretta"
  end

  test "MarkPostura Week Plan includes public database sessions from its professional calendar" do
    user = User.create!(email_address: "weekplan-database@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Mark Week Plan", username: "mark_week_plan")
    assignment = RoleAssignment.create!(profile: profile, role: :ideatore)
    professional = Node.create!(title: "Mark Postura", slug: "markpostura", node_type: :professional, role_assignment: assignment)
    brand = Node.create!(title: "PosturaCorretta", slug: "posturacorretta-weekplan", parent: professional, professional_owner_node: professional, role_assignment: assignment)
    calendar = ProfessionalCalendar.create!(context_node: brand, professional_node: professional, created_by_user: user, title: "Appuntamenti", slug: "postura-app", color: "blue")
    experience = DataExperience.create!(created_by_user: user, title: "Percorsi individuali")
    DataSession.create!(
      data_experience: experience,
      professional_calendar: calendar,
      visibility: "public",
      title: "Appuntamento dal database",
      starts_at: Time.zone.parse("2026-09-22 16:00"),
      ends_at: Time.zone.parse("2026-09-22 17:00")
    )

    get markpostura_weekplan_url(week: "2026-W39", calendars: "postura-app")

    assert_response :success
    assert_includes response.body, "Appuntamento dal database"
    assert_includes response.body, "data_session_id"
  end

  test "Rails4Business landing renders both current logo assets" do
    get rails4b_url

    assert_response :success
    assert_select "img[src*='rails4b_logo_quadrato']"
    assert_select "img[src*='rails4b_logo_lungo']", count: 0
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "guarda-flowpulse")}']", text: /Guarda Flowpulse/
    assert_select "a[href='#{rails4b_path(percorso: "collaborare")}']", text: /Voglio collaborare/
  end

  test "Rails4Business renders a published path article" do
    get rails4b_content_url("guarda-flowpulse")

    assert_response :success
    assert_select "h1", text: "Guarda Flowpulse"
    assert_select "h2", text: "La rete prima del singolo strumento"
  end

  test "Rails4Business hides scheduled drafts from the public" do
    get rails4b_content_url("parti-dal-bisogno")

    assert_response :success
    assert_select "h2", text: "Disponibile a breve"
    assert_select "h2", text: "Prima della soluzione", count: 0
  end

  test "Rails4Business separates dated content from the permanent train" do
    get rails4b_contents_url

    assert_response :success
    assert_select "h1", text: "Contenuti Rails4Business"
    assert_select "a[href='#{rails4b_contents_path(tab: "prossimi")}']", text: "Futuri"
    assert_select "a[href='#{rails4b_contents_path(tab: "passati")}']", text: "Passati"
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "installa-dash-wallet")}']", text: /Installa Dash Wallet/
  end

  test "Rails4Business switches to the collaboration train" do
    get rails4b_url(percorso: "collaborare")

    assert_response :success
    assert_select "h3", text: "Guarda Flowpulse"
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "guarda-flowpulse")}']", text: /Guarda Flowpulse/
  end

  test "Rails4Business renders a track show with its content aside" do
    get rails4b_track_url("collaborare", contenuto: "guarda-flowpulse")

    assert_response :success
    assert_select "aside", text: /Installa Dash Wallet/
    assert_select "h1", text: "Guarda Flowpulse"
  end
end
