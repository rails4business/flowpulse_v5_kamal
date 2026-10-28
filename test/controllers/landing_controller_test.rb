require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "Stato di Salute presents the two paths without simulating a clinical assessment" do
    get stato_di_salute_url

    assert_response :success
    assert_select "h1", "Come stai, davvero?"
    assert_select "nav a[href='#orientamento']", text: "Fai il test"
    assert_select "#human-areas"
    assert_select "#human-areas [data-area-tab]", count: 7
    assert_select "a[href='#{percorso_integrato_path}']", text: /Percorso Integrato/
    assert_select "a[href='#{posturacorretta_path}']", text: /PosturaCorretta/
    assert_select "nav a[href='#{giardino_del_corpo_path}']", text: "Il Giardino del Corpo"
    assert_select "article", text: /Dalla PosturaCorretta al Giardino del Corpo/
    assert_select "span", text: "Questionario in preparazione"
    assert_select "main", text: /non sostituirà diagnosi, visita o valutazione professionale/i

    get "/stato_di_salute"
    assert_redirected_to stato_di_salute_url
  end

  test "Igiene Posturale route stays inside GeneraImpresa while its Node is not public" do
    get igieneposturale_url

    assert_redirected_to "http://generaimpresa.it/generaimpresa"
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "Rails4Business landing separates problems from reusable skills" do
    get rails4b_url

    assert_response :success
    assert_select "nav[aria-label='Navigazione Rails4Business'] img[src='https://ik.imagekit.io/posturacorretta/sub_brands/loghi/rails4b.png']"
    assert_select "#rails4b-workspaces", text: /Problemi e Skill non sono la stessa cosa/
    assert_select "#rails4b-workspaces article", count: 2
    assert_select "a[href=?]", new_session_path(return_to: rails4b_problems_path)
    assert_select "a[href=?]", new_session_path(return_to: rails4b_skills_path)
  end

  test "Flowpulse presents MarkPostura as one world rather than the whole platform" do
    get flowpulse_url

    assert_response :success
    assert_select "h1", text: /Costruisci il tuo mondo.*Segui il tuo flow/m
    assert_select "figure[aria-labelledby='personal-flow-title personal-flow-caption']"
    assert_select "svg[aria-labelledby='personal-flow-title personal-flow-description']"
    assert_select "svg title", text: "Costruisci il tuo mondo con FlowPulse"
    assert_select "#come-funziona", text: /Il tuo mondo non deve assomigliare/
    assert_select "#mondo-markpostura", text: /Il FlowPulse costruito da MarkPostura/
    assert_select "#mondo-markpostura img[alt='Il FlowPulse costruito da MarkPostura']"
    assert_select "#mondo-markpostura", text: /Un’altra persona può partire da sfere completamente diverse/
    assert_select "a[href='#{genera_impresa_path}']", text: /Dai forma a un’idea/
  end

  test "Flowpulse navigation exposes one network directory and changelog" do
    get flowpulse_url

    assert_response :success
    assert_select "nav[aria-label='Navigazione Flowpulse'] a[href='#{flowpulse_global_network_path}']", text: "Rete"
    assert_select "nav[aria-label='Navigazione Flowpulse'] details summary", text: /Strumenti/
    assert_select "nav[aria-label='Navigazione Flowpulse'] details a[href='#{genera_impresa_path}']", text: /GeneraImpresa/
    assert_select "nav[aria-label='Navigazione Flowpulse'] details a[href='#{rails4b_path}']", text: /Rails4Business/
    assert_select "nav[aria-label='Navigazione Flowpulse'] details a[href='#{impegno_path}']", text: /1Impegno/
    assert_select "nav[aria-label='Navigazione Flowpulse'] a", text: "Mondi e Brand", count: 0
    assert_select "nav[aria-label='Navigazione Flowpulse'] a", text: "Professionisti", count: 0
    assert_select "nav[aria-label='Navigazione Flowpulse'] a[href='#{changelog_path}']", text: "Changelog"
    assert_select "footer a[href='https://github.com/rails4business/flowpulse_v5_kamal'][target='_blank']", text: /GitHub/
  end

  test "legacy Flowpulse projects directory redirects to the Brand tab" do
    get flowpulse_projects_url

    assert_redirected_to flowpulse_global_network_url(vista: "brand")
  end

  test "legacy world filter redirects to the unified Brand tab" do
    get flowpulse_projects_url(mondo: "markpostura")

    assert_redirected_to flowpulse_global_network_url(vista: "brand")
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
    assert_select ".accordion-study__path-intro", count: 1
    assert_select "#percorso-studio-title", text: "Tecnica classico-internazionale"
    assert_select "nav[aria-label='Percorsi della fisarmonica'] a", count: 4 do |tabs|
      assert_equal ["Tecnica classico-internazionale", "Irlandese / Folk", "Italiana", "Francese"], tabs.map { |tab| tab.text.strip }
    end
    assert_select "nav[aria-label='Studio della fisarmonica'] a", count: 6 do |tabs|
      assert_equal ["Cambieri-Fugazza-Melocchi", "Metodo Anzaghi", "Tecnica moderna", "Repertorio", "Fonti", "Contenuti"], tabs.map { |tab| tab.text.strip }
    end
    assert_select "a[href*='youtube.com/watch']", text: /Metodo per fisarmonica vol.1/

    get cantachetipassa_accordion_url(page: "canzoni", percorso: "folk")
    assert_response :success
    assert_select ".accordion-study__path-intro", count: 0
    assert_select "#percorso-studio-title", count: 0
    assert_select ".accordion-study__list h2", text: "Facili"
    assert_select ".accordion-study__list h2", text: "Medie"
    assert_select ".accordion-study__list h2", text: "Difficili"
    assert_select "#repertorio-progressivo-title", text: "Repertorio progressivo"
    assert_select ".accordion-piece", count: 10
    assert_select "#brano-wellerman", text: /Wellerman/
    assert_select "#brano-the-kesh-jig", text: /The Kesh Jig/
    assert_select "#brano-romagna-mia", count: 0
    assert_select ".accordion-piece__body dt", text: "Diteggiatura C-system"

    get cantachetipassa_accordion_url(page: "canzoni", percorso: "italian")
    assert_response :success
    assert_select ".accordion-repertoire__path", count: 1
    assert_select "#percorso-italian"
    assert_select "#brano-romagna-mia", text: /Romagna mia/
    assert_select "#percorso-folk", count: 0

    get cantachetipassa_accordion_url(page: "fonti")
    assert_response :success
    assert_select ".accordion-study__list a", count: 8
  end

  test "legacy professionals directory redirects to the Professional Brand tab" do
    host! "localhost"
    get flowpulse_professionals_url

    assert_redirected_to flowpulse_global_network_url(vista: "professional")
  end

  test "MarkPostura local route renders the editorial YAML home" do
    get markpostura_url

    assert_response :success
    assert_select "h1", text: "Ascolto le persone, do forma alle idee e collego chi può realizzarle."
    assert_select ".mp-sales__hero-world img[alt='Mark Postura']"
    assert_select "#percorsi .mp-sales__movement", count: 3
    assert_select "#percorsi", text: /Ascoltare.*Dare forma.*Mettere alla prova/m
    assert_select "#mondo-markpostura .mp-sales__entrance", count: 3
    assert_select "#mondo-markpostura a[href='#{flowpulse_projects_path(mondo: 'markpostura')}']", text: /MarkPostura/i
    assert_select "#mondo-markpostura a[href='#{flowpulse_projects_path}']", text: /tutti i Brand/i
    assert_select "#presentazione .mp-sales__program li", count: 4
    assert_select "#presentazione", text: /Mettiamo a fuoco il primo progetto su cui lavorare/
    assert_select "#contenuti .mp-sales__content-list > a", count: 3
    assert_select ".mp-sales__about", text: /Sono partito dalla fisioterapia.*ho iniziato a dare vita a progetti/m
    assert_select ".mp-sales__about .mp-sales__traits", text: /Origine.*Formazione.*Evoluzione/m
    assert_select ".mp-sales__about a[href='#{markpostura_timeline_path}']", text: /Formazione e linea del tempo/
    assert_select ".mp-sales__faq-list details", count: 5
    assert_select "#lista-attesa form[action='#{public_brand_requests_path}']"
    assert_select "#lista-attesa input[name='brand_request[kind]'][value='waitlist']"
    assert_select ".mp-sales__mobile-cta[href='#lista-attesa']"
    assert_select "body:not(.posturacorretta-ui)"
  end

  test "MarkPostura has a dedicated presentation page" do
    get markpostura_presentation_url

    assert_response :success
    assert_select "h1", text: "Un'ora per vedere il quadro completo"
    assert_select "#incontro", text: /Conoscere.*Costruire.*Esplorare.*Collegare/m
    assert_select "#dopo a[href='#{flowpulse_projects_path(mondo: 'markpostura')}']", text: /Conosci il mondo di MarkPostura/
    assert_select "#partecipa a[href^='mailto:markpostura@gmail.com']"
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
    assert_includes response.body, "Lezione di gruppo · Postura e salute: da dove iniziare"
    assert_not_includes response.body, "Pubblicazione corso · Postura e salute: da dove iniziare"
    assert_not_includes response.body, "Preparazione · Postura e salute: da dove iniziare"
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
    assert_select "img[src='https://ik.imagekit.io/posturacorretta/sub_brands/loghi/rails4b.png']"
    assert_select "img[src*='rails4b_logo_lungo']", count: 0
    assert_select "h1", text: "Problemi da risolvere. Skill da costruire e riutilizzare."
    assert_select "p", text: /Rails4Business tiene separate due cose/
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

  test "Rails4Business publishes the politics and economy article" do
    get rails4b_content_url("riprenderci-la-politica-partendo-dall-economia")

    assert_response :success
    assert_select "h1", text: "Riprenderci la politica, partendo dall'economia"
    assert_select "h2", text: /Partire da un comune/
    assert_select "a[href='#{genera_impresa_project_path("ripartire-con-dash")}']", text: /Apri il progetto Ripartire con Dash/

    get rails4b_contents_url(tab: "contenuti")
    assert_response :success
    assert_select "a[href='#{rails4b_content_path("riprenderci-la-politica-partendo-dall-economia")}']"
  end

  test "Rails4Business separates dated content from the permanent train" do
    get rails4b_contents_url

    assert_response :success
    assert_select "h1", text: "Contenuti Rails4Business"
    assert_select "nav[aria-label='Contenuti ed eventi']", count: 0
    assert_select "a[href='#{rails4b_contents_path(tab: "eventi")}']", count: 0
    assert_select "a[href='#{rails4b_contents_path(tab: "contenuti")}']", count: 0
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "installa-dash-wallet")}']", text: /Installa Dash Wallet/
  end

  test "Rails4Business keeps the new focus when a legacy track is selected" do
    get rails4b_url(percorso: "collaborare")

    assert_response :success
    assert_select "h1", text: "Problemi da risolvere. Skill da costruire e riutilizzare."
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
