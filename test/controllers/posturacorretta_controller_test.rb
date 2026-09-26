require "test_helper"

class PosturacorrettaControllerTest < ActionDispatch::IntegrationTest
  test "publishes the health is not a luxury article as PosturaCorretta content" do
    get posturacorretta_articolo_path("la-salute-non-e-un-lusso")

    assert_response :success
    assert_select "h1", text: "La salute non è un lusso: un percorso integrato per tutti"
  end

  test "redirects former first-month guide URLs to the book" do
    get posturacorretta_guida_url(sezione: "primo_mese", capitolo: "02-benefici")

    assert_response :moved_permanently
    assert_redirected_to book_chapter_path(book_slug: "postura-corretta-in-un-mese", id: "benefici-postura-corretta")
  end

  test "redirects the former first-month landing to the book cover" do
    get posturacorretta_primo_mese_url

    assert_response :moved_permanently
    assert_redirected_to book_chapter_path(book_slug: "postura-corretta-in-un-mese", id: "copertina")
  end

  test "does not index filtered content listings" do
    get posturacorretta_contenuti_path(ambito: "dolore", area: "cura")

    assert_response :success
    assert_select 'link[rel="canonical"][href$="/posturacorretta/contenuti"]'
    assert_select 'meta[name="robots"][content="noindex, follow"]'
  end

  test "keeps its own how-it-works guide distinct from the Percorso Integrato docs" do
    get posturacorretta_path

    assert_response :success
    assert_select "a[href='#{posturacorretta_guida_path(sezione: "accademia", capitolo: "educazione")}']", text: "Come funziona"
    assert_select "a[href='#{percorso_integrato_docs_path}']", count: 0
  end

  test "shows dated events alongside contents with compact period controls" do
    get posturacorretta_contenuti_path(periodo: "prossimi")

    assert_response :success
    assert_select "nav[aria-label='Periodo contenuti'] a", text: "Prossimi"
    assert_select "summary", text: /Filtra/
    assert_select ".blog-article[data-kind='masterclass']", minimum: 1
  end

  test "should get the educational path landing page" do
    get posturacorretta_url
    assert_response :success
    assert_includes response.body, "Percorso educativo PosturaCorretta"
  end

  test "keeps the legacy academy curriculum available" do
    get posturacorretta_accademia_url
    assert_response :success
    assert_includes response.body, "Accademia"
  end

  test "shows teachers in PosturaCorretta and redirects professionals to Percorso Integrato" do
    get posturacorretta_insegnanti_path
    assert_response :success
    assert_select "h1", text: "Insegnanti PosturaCorretta"
    assert_select "h2", text: "Mark Postura"
    assert_select "h2", text: "Davide Cattaneo", count: 0
    assert_select "a[href='#{posturacorretta_insegnante_path("markpostura")}'] img[alt='Foto profilo di Mark Postura']"

    get posturacorretta_insegnante_path("markpostura")
    assert_response :success
    assert_select "h1", text: "Mark Postura"
    assert_select "nav[aria-label='Profilo insegnante'] a:first-child", text: "Orario"
    assert_select "h2", text: "Gruppi e appuntamenti"
    assert_select "a[href='#{markpostura_weekplan_path}']", text: "Apri il Week Plan di MarkPostura →"

    get posturacorretta_insegnante_path("markpostura", tab: "training")
    assert_response :success
    assert_select "h2", text: "Formazione insegnante PosturaCorretta"
    assert_select "table[aria-label='Formazione del fondatore'] td", text: "2004–2007"
    assert_select "a[href='#{posturacorretta_metodica_path("osteopatia")}']", text: "Osteopatia"
    assert_select "h3", text: "Fondamenti"
    assert_select "h3", text: "Recupero"
    assert_select "table[aria-label='Introduzione a PosturaCorretta'] th", text: "Insegnante"
    assert_select "table[aria-label='Introduzione a PosturaCorretta'] td", text: "Mark Postura"
    assert_select "table[aria-label='Introduzione a PosturaCorretta'] td", text: /1\. Inizia con PosturaCorretta/
    assert_select "table[aria-label='Introduzione a PosturaCorretta'] td", text: /2\. Postura e Fisiologia/
    assert_select "table[aria-label='Principi di Fisioterapia']"
    assert_select "table[aria-label='Biomeccanica comportamentale (GDS)']"
    assert_select "table[aria-label='Principi di Osteopatia']"
    assert_select "table[aria-label='Corpo e Coscienza']"
    assert_select "table[aria-label='Altre metodiche posturali']"
    assert_select "h3", text: "Riconoscere il percorso svolto"
    assert_select "[data-teacher-internship]", count: 0

    get posturacorretta_insegnante_path("markpostura", tab: "centres")
    assert_response :success
    assert_select "a[href='#{posturacorretta_centre_path("centro-posturacorretta")}']", text: /Apri centro/

    get posturacorretta_insegnante_path("insegnante-inesistente")
    assert_redirected_to posturacorretta_insegnanti_path

    get posturacorretta_professionisti_path
    assert_redirected_to percorso_integrato_professionals_path
    assert_response :moved_permanently

    get posturacorretta_professionista_path("giovanni-damiata")
    assert_redirected_to percorso_integrato_professional_path("giovanni-damiata")
    assert_response :moved_permanently
  end

  test "shows only PosturaCorretta places in its directory" do
    get posturacorretta_lesson_centres_path
    assert_response :success
    assert_select "h1", text: "Centri PosturaCorretta"
    assert_select "nav[aria-label='Lezioni PosturaCorretta']"
    assert_select "section[aria-label='Modalità delle lezioni']", text: /Singolo/
    assert_select "section[aria-label='Modalità delle lezioni']", text: /Gruppo/
    assert_select "section[aria-label='Modalità delle lezioni']", text: /Online/
    assert_select "section[aria-label='Mappa dei centri PosturaCorretta'] #posturacorretta-centres-map[data-centres]"
    assert_select "iframe", count: 0
    assert_select "h2", text: "Sede PosturaCorretta · Cascina Bordonala"
    assert_select "h2", text: "Studio Movimento", count: 0
    assert_select "a[href='#{posturacorretta_centre_path("centro-posturacorretta")}']"
    assert_select "h2", text: "Giardino del Corpo", count: 0

    get posturacorretta_centre_path("centro-posturacorretta")
    assert_response :success
    assert_select "h1", text: "Sede PosturaCorretta · Cascina Bordonala"
    assert_select "nav[aria-label='Centro PosturaCorretta'] a", text: "Insegnanti"
    assert_select "nav[aria-label='Centro PosturaCorretta'] a", text: "Orari"
    assert_select "nav[aria-label='Centro PosturaCorretta'] a", text: "Info"
    assert_select "h2", text: "Chi insegna qui"

    get posturacorretta_centre_path("centro-posturacorretta", tab: "info")
    assert_select "h2", text: "Come partecipare"
    assert_select "section[aria-label='Mappa della sede'] #posturacorretta-centre-map[data-latitude][data-longitude]"

    get posturacorretta_percorsi_sul_territorio_path(tab: "people")
    assert_redirected_to posturacorretta_insegnanti_path
    assert_response :moved_permanently
  end

  test "shows the teacher YAML source only to a superadmin" do
    get posturacorretta_insegnante_path("markpostura")
    assert_select "aside[aria-label='Sorgente profilo insegnante']", count: 0

    superadmin = User.create!(email_address: "teacher-source-superadmin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
    post session_path, params: { email_address: superadmin.email_address, password: "password123" }
    get posturacorretta_insegnante_path("markpostura")

    assert_select "a[href='#{admin_didactic_source_path(path: "teachers/markpostura.yml")}']", text: "Dati insegnante · markpostura.yml"
    assert_select "a[href='#{admin_didactic_source_path(path: "teachers/markpostura.md")}']", text: "Bio · markpostura.md"

    get posturacorretta_insegnante_path("markpostura", tab: "training")
    assert_select "[data-teacher-internship]", minimum: 1
    assert_includes response.body, "Svolgere una pratica in compresenza con una persona."
  end

  test "renders professional collaboration guides from markdown" do
    {
      "contenuti-video" => "contenuti",
      "promuovi-metodica-professione" => "metodica-professione",
      "eventi" => "eventi"
    }.each do |slug, chapter|
      get posturacorretta_collabora_professionisti_guida_url(slug)

      assert_response :moved_permanently
      assert_redirected_to posturacorretta_path(sezione: "collabora", capitolo: chapter)
    end
  end

  test "redirects the integrated collaboration guide into percorso" do
    get posturacorretta_collabora_professionisti_guida_url("percorso-integrato")

    assert_redirected_to posturacorretta_path(sezione: "collabora", capitolo: "percorso-integrato")
  end

  test "redirects an unknown professional collaboration guide" do
    get posturacorretta_collabora_professionisti_guida_url("inesistente")

    assert_redirected_to posturacorretta_collabora_professionisti_path
  end

  test "redirects the retired PosturaCorretta percorso pages to Percorso Integrato" do
    get posturacorretta_percorso_url
    assert_response :moved_permanently
    assert_redirected_to percorso_integrato_path
  end

  test "should get metodiche index" do
    get posturacorretta_metodiche_url
    assert_response :success
    assert_includes response.body, "Professioni, metodiche posturali e per la guarigione"
    assert_includes response.body, "Biomeccanica Comportamentale GDS"
  end

  test "should get metodica show" do
    get posturacorretta_metodica_url("gds")
    assert_response :success
    assert_includes response.body, "Godelieve Denys-Struyf"
    assert_includes response.body, "Professionisti collegati"
    assert_select "body.posturacorretta-ui"
    assert_select "article.pc-rich-text h1", text: "Biomeccanica Comportamentale GDS"
    assert_select "a[href='#{percorso_integrato_professional_path("sara-moretti")}']", text: "Vedi profilo e contatti su Percorso Integrato →"
  end

  test "should get contenuti" do
    get posturacorretta_contenuti_url
    assert_response :success
    assert_includes response.body, "Contenuti"
    assert_select ".macro-tab", count: 0
    assert_select ".blog-section[data-category='tutti']", count: 1
    assert_select ".blog-section[data-category='corsi']", count: 0
  end

  test "renders a content migrated into the canonical Brand directory" do
    get posturacorretta_articolo_url("consapevolezza-e-coscienza-corporea")

    assert_response :success
    assert_includes response.body, "Consapevolezza e coscienza corporea: due percorsi diversi"
    assert_includes response.body, "fisiologia → sensazione → percezione diretta"
  end

  test "should get corsi as a separate catalog" do
    get posturacorretta_corsi_url

    assert_response :success
    assert_select ".macro-tab", count: 0
    assert_select "input[placeholder='Cerca un corso...']", count: 1
    assert_select ".blog-section[data-category='corsi']", count: 1
    assert_select ".blog-section[data-category='tutti']", count: 0
  end

  test "redirects the former course category to the courses page" do
    get posturacorretta_contenuti_url(categoria: "corsi")

    assert_redirected_to posturacorretta_corsi_url
    assert_response :moved_permanently
  end

  test "should get eventi" do
    get posturacorretta_eventi_url
    assert_response :success
    assert_includes response.body, "Eventi e Community"
  end

  test "eventi exposes the how tab through a parameter" do
    get posturacorretta_eventi_url(tab: "how")

    assert_response :moved_permanently
    assert_redirected_to posturacorretta_path(sezione: "eventi", capitolo: "introduzione")
  end

  test "should get visione" do
    get posturacorretta_visione_url
    assert_response :moved_permanently
    assert_redirected_to "/posturacorretta/guida?sezione=progetto&capitolo=visione"
  end

  test "legacy libro and filosofia redirect to visione" do
    get posturacorretta_libro_url
    assert_redirected_to posturacorretta_visione_url

    get posturacorretta_filosofia_url
    assert_redirected_to posturacorretta_visione_url
  end

  test "should get collabora" do
    get posturacorretta_collabora_url
    assert_response :success
    assert_includes response.body, "Collabora con noi"
  end

  test "should get progetti" do
    get posturacorretta_progetti_url
    assert_response :success
    assert_includes response.body, "Progetti"
  end

  test "should get progetto by slug" do
    get posturacorretta_progetto_url("accademia-posturacorretta")
    assert_response :success
    assert_includes response.body, "Accademia PosturaCorretta"
  end

  test "missing progetto redirects to index" do
    get posturacorretta_progetto_url("progetto-inesistente")
    assert_redirected_to posturacorretta_progetti_url
  end
end
