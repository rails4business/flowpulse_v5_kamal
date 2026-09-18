require "test_helper"

class PosturacorrettaControllerTest < ActionDispatch::IntegrationTest
  test "does not index filtered content listings" do
    get posturacorretta_contenuti_path(ambito: "dolore", area: "cura")

    assert_response :success
    assert_select 'link[rel="canonical"][href$="/posturacorretta/contenuti"]'
    assert_select 'meta[name="robots"][content="noindex, follow"]'
  end

  test "shows dated events alongside contents with compact period controls" do
    get posturacorretta_contenuti_path(periodo: "prossimi")

    assert_response :success
    assert_select "nav[aria-label='Periodo contenuti'] a", text: "Prossimi"
    assert_select "summary", text: /Filtra/
    assert_select ".blog-article[data-kind='masterclass']", minimum: 1
  end

  test "should get accademia (landing page)" do
    get posturacorretta_url
    assert_response :success
    assert_includes response.body, "Accademia"
  end

  test "should get dedicated accademia page" do
    get posturacorretta_accademia_url
    assert_response :success
    assert_includes response.body, "Accademia"
    assert_select "#collabora-accademia"
    assert_select "#collabora-accademia h2", text: "Chi aiuta le persone a conoscere il proprio corpo?"
    assert_select "#collabora-accademia h4", text: "Porta l'Accademia nel tuo centro"
    assert_select "#collabora-accademia h4", text: "Segreteria e team management"
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
    assert_select "table[aria-label='Inizia con PosturaCorretta'] th", text: "Insegnante"
    assert_select "table[aria-label='Inizia con PosturaCorretta'] td", text: "Mark Postura"
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
    assert_includes response.body, "Condurre una lezione individuale con un paziente, con supervisione."
  end

  test "renders professional collaboration guides from markdown" do
    {
      "contenuti-video" => "Collabora alla creazione di contenuti",
      "promuovi-metodica-professione" => "Presenta una metodica o una professione",
      "eventi" => "Organizza o partecipa a un evento"
    }.each do |slug, title|
      get posturacorretta_collabora_professionisti_guida_url(slug)

      assert_response :success
      assert_select "article.pc-rich-text h1", text: title
    end
  end

  test "redirects the integrated collaboration guide into percorso" do
    get posturacorretta_collabora_professionisti_guida_url("percorso-integrato")

    assert_redirected_to posturacorretta_percorso_path(page: "professionisti-percorso-integrato")
  end

  test "redirects an unknown professional collaboration guide" do
    get posturacorretta_collabora_professionisti_guida_url("inesistente")

    assert_redirected_to posturacorretta_collabora_professionisti_path
  end

  test "should get percorso" do
    get posturacorretta_percorso_url
    assert_response :success
    assert_includes response.body, "Inizia un percorso"
    assert_includes response.body, "Pazienti"
    assert_includes response.body, "Inizia da qui"
  end

  test "should render professional guide from markdown" do
    get posturacorretta_percorso_url(page: "professionisti-iniziare-percorso")

    assert_response :success
    assert_select "h1", text: "Come iniziare il percorso"
    assert_select "nav[aria-label='Titoli del documento'] a[href='#raccogliere-le-informazioni-iniziali']", text: "Raccogliere le informazioni iniziali"
  end

  test "renders the integrated professional path as a guide" do
    get posturacorretta_percorso_url(page: "professionisti-percorso-integrato")

    assert_response :success
    assert_select "h1", text: "Collaborare in un percorso integrato"
    assert_select "a[href='#{posturacorretta_percorso_path(page: 'professionisti-percorso-integrato')}'].font-normal.text-slate-500", text: "Collaborare in un percorso integrato"
    assert_select "a.pc-inline-cta[href='#{posturacorretta_percorso_path(page: 'professionisti-aderisci-linee-guida')}']", text: /Scopri come aderire/
    assert_select "a[href^='https://wa.me/']", count: 0
    assert_includes response.body, "La futura cerchia dei collaboratori"
  end

  test "renders adherence as the final professional guideline with whatsapp calls to action" do
    get posturacorretta_percorso_url(page: "professionisti-aderisci-linee-guida")

    assert_response :success
    assert_select "h1", text: "Aderisci alle Linee guida del Percorso"
    assert_select "section#adesione-linee-guida h2", text: "Aderisci alle Linee guida del Percorso"
    assert_select "a.pc-cta-primary[href^='https://wa.me/393792891488?text=']", text: "Aderisci", count: 1
    assert_select "a.pc-cta-secondary[href^='https://wa.me/393792891488?text=']", text: "Chiedi informazioni", count: 1
    assert_select "a.pc-inline-cta[href='#adesione-linee-guida']", text: /Torna all'adesione/
  end


  test "links professional guidelines to adherence" do
    get posturacorretta_percorso_url(page: "professionisti-iniziare-percorso")

    assert_response :success
    assert_select "a.pc-inline-cta[href='#{posturacorretta_percorso_path(page: 'professionisti-aderisci-linee-guida')}']", text: /Scopri come aderire/
  end

  test "renders physiological reasoning and outcome measurement guidelines" do
    get posturacorretta_percorso_url(page: "professionisti-ragionamento-fisiologico")
    assert_response :success
    assert_select "h1", text: "Spiegare il ragionamento fisiologico"
    assert_select "h2", text: "Due livelli di spiegazione"
    assert_select "h2", text: "Dichiarare i risultati attesi"

    get posturacorretta_percorso_url(page: "professionisti-misurare-risultati")
    assert_response :success
    assert_select "h1", text: "Misurare i risultati"
    assert_select "h2", text: "Migliorare senza confondere esperienza e prova scientifica"
    assert_select "h2", text: "Strumento futuro"
  end

  test "markdown percorso has a linked heading-only index" do
    get posturacorretta_percorso_url(page: "stop-al-dolore")

    assert_response :success
    assert_select "article.pc-rich-text h1#stop-al-dolore", "Stop al dolore"
    assert_select "nav.path-document-toc a[href='#stop-al-dolore']", "Stop al dolore"
    assert_operator css_select("nav.path-document-toc a").size, :>=, 10
    assert_select "nav.path-document-toc", text: /Questa linea guida/, count: 0
  end

  test "should get metodiche index" do
    get posturacorretta_metodiche_url
    assert_response :success
    assert_includes response.body, "Scopri di più sulle metodiche"
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

    assert_response :success
    assert_select "a[href=?][aria-current=page]", posturacorretta_eventi_path(tab: "how"), text: /Come funziona/
    assert_includes response.body, "Per conduttori e professionisti"
    assert_includes response.body, "Per location e associazioni"
  end

  test "should get visione" do
    get posturacorretta_visione_url
    assert_response :success
    assert_includes response.body, "La visione"
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
