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

  test "Canta che ti passa links to its four sessions and participation sections" do
    get cantachetipassa_url

    assert_response :success
    assert_select "#sessioni"
    assert_select "#partecipa"
    assert_select "a[href='#{cantachetipassa_path}#sessioni']", text: "Le quattro sessioni"
    assert_select "a[href='#sessioni']", text: "Scopri le quattro sessioni"
    assert_select "a[href='#{cantachetipassa_path}#partecipa']", text: "Partecipa"
    assert_select "#sessioni h3", count: 4
    assert_select "#sessioni", text: /Canto.*Fisarmonica.*Chitarra/m
    assert_select "a[href='#{cantachetipassa_accordion_path}']", text: "Fisarmonica"
  end

  test "accordion study has ordered tabs and YAML backed pages" do
    get cantachetipassa_accordion_url

    assert_response :success
    assert_select "h1", text: "Fisarmonica"
    assert_select "nav[aria-label='Studio della fisarmonica'] a", count: 6 do |tabs|
      assert_equal %w[Cambieri Anzaghi Tecnica Canzoni Fonti Contenuti], tabs.map { |tab| tab.text.strip }
    end
    assert_select "a[href*='youtube.com/playlist']", text: /Metodo per fisarmonica vol.1/

    get cantachetipassa_accordion_url(page: "canzoni")
    assert_response :success
    assert_select ".accordion-study__list h2", text: "Facili"
    assert_select ".accordion-study__list h2", text: "Medie"
    assert_select ".accordion-study__list h2", text: "Difficili"

    get cantachetipassa_accordion_url(page: "fonti")
    assert_response :success
    assert_select ".accordion-study__list a", count: 8
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
    assert_select "h1", text: "Ambiente, Esperienze e Relazioni"
    assert_select "#progetti a", count: 3
    assert_select "#ingresso li", count: 4
    assert_select "#progetti [data-language-card]", count: 3
    assert_select "#prospettiva h3", text: "Vivere"
    assert_select "#prospettiva h3", text: "Comprendere"
    assert_select "#prospettiva h3", text: "Costruire"
    assert_select "#progetti", text: /Fisiologia/
    assert_select "#approfondisci a", count: 3
    assert_select "#approfondisci a[href='/markpostura/contenuti/dal-bio-psico-sociale-al-vivere-comprendere-costruire']"
    assert_select "#timeline iframe", count: 0
    assert_select "#timeline [data-timeline-deferred]"
    assert_select "#timeline button[data-timeline-trigger]", text: "Carica ora"
    assert_select "body:not(.posturacorretta-ui)"
    assert_select ".editorial-action-button", count: 5
  end

  test "MarkPostura publishes the bio psycho social article" do
    get markpostura_content_url("dal-bio-psico-sociale-al-vivere-comprendere-costruire")

    assert_response :success
    assert_select "h1", text: "Dal bio-psico-sociale al vivere, comprendere e costruire"
    assert_select "article h2", text: "Bio: vivere"
    assert_select "article h2", text: "Psico: comprendere"
    assert_select "article h2", text: "Sociale: costruire"
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
    assert_not_includes response.body, "Pubblicazione corso · Inizia con PosturaCorretta"
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

  test "Rails4Business landing presents digital work, processes and connected tools" do
    get rails4b_url

    assert_response :success
    assert_select "img[src*='rails4b_logo_quadrato']"
    assert_select "img[src*='rails4b_logo_lungo']", count: 0
    assert_select "h1", text: "Dalla persona ai processi che fanno funzionare l'impresa."
    assert_select "p", text: /La persona crea o realizza un'impresa/
    assert_select "h2", text: "Ogni persona può ideare o realizzare"
    assert_select "h2", text: "Come si collegano persone, Brand, progetti, attività e processi"
    assert_select "h3", text: "Persona e Brand"
    assert_select "h3", text: "Attività e processo"
    assert_select "h2", text: "Brand professionale e Brand progetto"
    assert_select "h3", text: "Brand professionale"
    assert_select "h3", text: "Brand progetto"
    assert_select "a[href='#{markpostura_path}']", text: /MarkPostura/
    assert_select "a[href='#{posturacorretta_path}']", text: /PosturaCorretta/, minimum: 1
    assert_select "h2", text: "Costruire una propria rete di Brand"
    assert_select "h3", text: "Reti che comunicano"
    assert_select "h2", text: "Un ecosistema, strumenti con responsabilità diverse"
    assert_select "h2", text: "Il canale YouTube come sottoprogetto"
    assert_select "h2", text: "Salute, digitale e stile di vita sono collegati"
    assert_select "h2", text: "Shape Up e 37signals — fonti originali"
    assert_select "a[href='https://basecamp.com/shapeup'][target='_blank']", text: /Shape Up/
    assert_select "a[href='https://37signals.com/books'][target='_blank']", text: /Libri di 37signals/
    assert_select "a[href='https://bookshop.org/p/books/rework-david-heinemeier-hansson/16cd5b1a12549f52?ean=9780307463746'][target='_blank']", text: /REWORK/
    assert_select "a[href='https://37signals.com/13'][target='_blank']", text: /On repeat/
    assert_select "a[href='https://37signals.com/podcast/'][target='_blank']", text: /REWORK Podcast/
    assert_select "a[href='https://github.com/DietrichGebert/ponytail'][target='_blank']", text: /Ponytail/
    assert_select "a[href='#{flowpulse_path}']", text: /Flowpulse/, minimum: 1
    assert_select "a[href='#{rails4b_contents_path}']", text: /contenuti/i, minimum: 1
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

  test "Rails4Business publishes the cellula sociale article" do
    get rails4b_content_url("dalla-banca-alla-cellula-sociale")

    assert_response :success
    assert_select "h1", text: "Dalla banca alla cellula sociale: come rappresentare un organismo che cresce"
    assert_select "h2", text: "Come far crescere un'organizzazione dove le regole sono fatte per chi è già grande"

    get rails4b_contents_url(tab: "contenuti")

    assert_response :success
    assert_select "a[href='#{rails4b_content_path("dalla-banca-alla-cellula-sociale")}']"
  end

  test "Rails4Business separates dated content from the permanent train" do
    get rails4b_contents_url

    assert_response :success
    assert_select "h1", text: "Contenuti Rails4Business"
    assert_select "a[href='#{rails4b_contents_path(tab: "eventi")}']", text: "Eventi"
    assert_select "a[href='#{rails4b_contents_path(tab: "contenuti")}']", text: "Contenuti"
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "installa-dash-wallet")}']", text: /Installa Dash Wallet/
  end

  test "Rails4Business keeps the new focus when a legacy track is selected" do
    get rails4b_url(percorso: "collaborare")

    assert_response :success
    assert_select "h1", text: "Dalla persona ai processi che fanno funzionare l'impresa."
    assert_select "h2", text: "Ogni persona può ideare o realizzare"
    assert_select "h3", text: "Guarda Flowpulse", count: 0
  end

  test "Rails4Business renders a track show with its content aside" do
    get rails4b_track_url("collaborare", contenuto: "guarda-flowpulse")

    assert_response :success
    assert_select "aside", text: /Installa Dash Wallet/
    assert_select "h1", text: "Guarda Flowpulse"
  end
end
