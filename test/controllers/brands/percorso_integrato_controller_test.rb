require "test_helper"

module Brands
  class PercorsoIntegratoControllerTest < ActionDispatch::IntegrationTest
    test "shows the example person sheet as home" do
      get percorso_integrato_path

      assert_response :success
      assert_select "h1", text: "Come si costruisce il tuo percorso"
      assert_select "article[aria-label='Scheda di esempio']", text: /Esempio.*di fantasia/m
      assert_select "#pi-sheet-persona", text: /La persona/
      assert_select "ul[aria-label='Ambito della richiesta'] li", count: 3
      assert_select "ul[aria-label='Ambito della richiesta'] li", text: /Dolore \/ patologia\s*\(richiesto\)/
      assert_select "section[aria-labelledby='pi-sheet-presa']", text: /Apertura del percorso.*presa in carico.*Laura Fisioterapista/m
      assert_select "#pi-panel-professionisti li", text: /Laura Fisioterapista.*Ha aperto il percorso/m
      assert_select "ul[aria-label='Aree su cui lavorare'] li", count: 5
      assert_select "ul[aria-label='Aree su cui lavorare'] li", text: /Recupero\s*\(proposta\)/
      assert_select "#pi-sheet-professionisti", text: /Professionisti/
      assert_select "[role='tablist'][aria-label='Sezioni della scheda'] [role='tab']", count: 3
      assert_select "#pi-tab-info[aria-selected='true']", text: "Info"
      assert_select "#pi-panel-professionisti[hidden]"
      assert_select "[role='tablist'][aria-label='Filtra il calendario'] [role='tab']", count: 5
      assert_select "#pi-calendar-tutte .pi-sheet-session", count: 5
      assert_select "#pi-calendar-benessere", text: /Nessuna seduta in questo ambito/
      assert_select "#pi-calendar-autonomia .pi-sheet-week__day", count: 7
      assert_select "a[href='#{percorso_integrato_guidelines_path}']", text: /Come funziona il Percorso Integrato/
      assert_select "nav[aria-label='Navigazione Percorso Integrato']"
      assert_select "details.pi-mobile-menu summary[aria-label='Apri il menu di Percorso Integrato']", text: /Menu/
      assert_select "nav[aria-label='Navigazione mobile Percorso Integrato']" do
        assert_select "a[href='#{percorso_integrato_path}']", text: "Home"
        assert_select "a[href='#{percorso_integrato_guidelines_path}']", text: "Linee guida"
        assert_select "a", text: /About|Modello esteso|Docs|Chi partecipa/, count: 0
        assert_select "a[href='#{percorso_integrato_guidelines_path(anchor: "inizia")}']", text: "Inizia"
      end
      assert_select "header img[src*='percorso_integrato_vecchio.png']"
      assert_select "nav[aria-label='Navigazione Percorso Integrato'] a[href='#{percorso_integrato_guidelines_path}']", text: "Linee guida"
    end

    test "assembles presentation complete model and public documentation in the guidelines" do
      get percorso_integrato_guidelines_path

      assert_response :success
      assert_select "main h1", count: 1, text: "Linee guida"
      assert_select "#presentazione #tre-campi", text: /Cura delle patologie.*Benessere.*Educazione PosturaCorretta/m
      assert_select "#modello #come-funziona"
      assert_select "#presa-in-carico", text: /un professionista apre il primo programma/
      assert_select "#presa-in-carico dt", text: "Problema"
      assert_select "#presa-in-carico dt", text: "Possibili cause"
      assert_select "#presa-in-carico dt", text: "Principi e metodiche"
      assert_select "#presa-in-carico dt", text: "Feedback"
      assert_select "details summary", text: /I sette ambiti della persona/
      assert_select "details summary", text: /Le cinque aree di intervento/
      assert_select "#percorso .pi-upgrade__level", count: 7
      assert_select "#percorso", text: /Salute a rischio.*Connessione/m
      assert_select "details.pi-upgrade__deep"
      assert_select "#ruoli"
      assert_select "#inizia"
      assert_select "#passi-per-iniziare h3", text: "Conosci il primo professionista"
      assert_select "a[href^='https://wa.me/393792891488']", text: "Scrivi su WhatsApp"
      assert_select "#doc-introduzione", text: /Il Percorso Integrato aiuta a partire da bisogni e obiettivi concreti/

      sections = YAML.safe_load_file(Rails.root.join("config/data/brands/percorso-integrato/docs/indice.yml")).fetch("sections")
      public_documents = sections.reject { |section| section["visibility"] == "internal_tutor" }.flat_map { |section| section.fetch("items") }
      public_documents.each do |document|
        assert_select "details[id='doc-#{document.fetch('slug')}']", count: 1
      end
      assert_select "#documentazione details[id^='doc-']", count: public_documents.size
      assert_select "#documentazione-tutor", count: 0
      assert_select "#doc-valutare-richiesta", count: 0
      ids = css_select("main [id]").map { |element| element["id"] }
      assert_equal ids.uniq, ids, "Every section and document needs a distinct anchor"
    end

    test "old About and model URLs redirect to guidelines" do
      get percorso_integrato_about_path
      assert_redirected_to percorso_integrato_guidelines_path
      assert_response :moved_permanently

      get percorso_integrato_model_path
      assert_redirected_to percorso_integrato_guidelines_path(anchor: "modello")
      assert_response :moved_permanently
    end

    test "redirects the former PosturaCorretta path to the standalone brand" do
      get posturacorretta_percorso_path

      assert_redirected_to percorso_integrato_path
      assert_response :moved_permanently
    end

    test "shows its own docs and redirects the former PosturaCorretta guide section" do
      get percorso_integrato_docs_path

      assert_redirected_to percorso_integrato_guidelines_path(anchor: "documentazione")
      assert_response :moved_permanently
      follow_redirect!
      assert_select "#doc-introduzione", text: /Il Percorso Integrato aiuta a partire da bisogni e obiettivi concreti/
      assert_select ".editorial-rich-text.editorial-rich-text--emerald"
      assert_select "nav[aria-label='Navigazione Percorso Integrato'] a", text: "PosturaCorretta", count: 0

      get posturacorretta_guida_path(sezione: "percorso")

      assert_response :moved_permanently
      assert_redirected_to percorso_integrato_docs_path

      get posturacorretta_guida_path(sezione: "percorso", capitolo: "professionisti-iniziare-percorso")

      assert_response :moved_permanently
      assert_redirected_to percorso_integrato_docs_path(doc: "iniziare-percorso")

      get percorso_integrato_docs_path(doc: "scegli-programma")

      assert_redirected_to percorso_integrato_guidelines_path(doc: "scegli-programma", anchor: "doc-scegli-programma")
      assert_response :moved_permanently
      follow_redirect!
      assert_select "#doc-scegli-programma[open] h4", text: "Parti dal bisogno che senti più vicino."
      assert_select "a.pi-button.pi-button--primary", text: "Chiedi orientamento su WhatsApp"
      assert_select "#doc-scegli-programma a[href^='/posturacorretta']", count: 0
    end

    test "guidelines preserve tutor documents for the superadmin only" do
      get percorso_integrato_guidelines_path(doc: "valutare-richiesta")
      assert_response :success
      assert_select "#documentazione-tutor", count: 0
      assert_select "#doc-valutare-richiesta", count: 0

      user = User.create!(email_address: "guidelines-superadmin@example.com", password: "password123", superadmin: true)
      user.create_profile!(display_name: "Guidelines superadmin")
      post session_path, params: { email_address: user.email_address, password: "password123" }
      get percorso_integrato_guidelines_path(doc: "valutare-richiesta")

      assert_response :success
      assert_select "#documentazione-tutor details", count: 3
      assert_select "#doc-valutare-richiesta[open]"
    end

    test "includes every course chapter in guidelines and preserves old chapter links" do
      get percorso_integrato_course_path

      assert_redirected_to percorso_integrato_guidelines_path(anchor: "corso")
      assert_response :moved_permanently
      follow_redirect!
      assert_select "#corso details[id^='capitolo-']", count: 8
      assert_select "#corso details:first-child summary", text: /Capitolo 01.*In arrivo.*Questionario iniziale del Percorso Integrato/m
      assert_select "nav[aria-label='Navigazione Percorso Integrato'] a", text: "Corso", count: 0
      assert_select "#capitolo-matrice-per-orientarsi-salute-benessere", text: /Una Matrice per orientarsi nella salute e nel benessere/
      assert_select "#capitolo-tre-colori-professionisti-insegnanti", text: /Semplifichiamo con tre colori/

      slug = "rete-professionisti-centri-pubbliche-amministrazioni"
      get percorso_integrato_course_chapter_path(slug)
      assert_redirected_to percorso_integrato_guidelines_path(capitolo: slug, anchor: "capitolo-#{slug}")
      assert_response :moved_permanently
      follow_redirect!
      assert_select "#capitolo-#{slug}[open] .editorial-rich-text", text: /La rete cresce informando persone, professionisti, centri e pubbliche amministrazioni/
      assert_not_includes response.body, "author_node_slug"

      slug = "questionario-iniziale-percorso-integrato"
      get percorso_integrato_course_chapter_path(slug)
      assert_redirected_to percorso_integrato_guidelines_path(capitolo: slug, anchor: "capitolo-#{slug}")
      follow_redirect!
      assert_select "#capitolo-#{slug}[open] .editorial-rich-text", text: /Questionario iniziale del Percorso Integrato/

      get percorso_integrato_course_chapter_path("capitolo-inesistente")
      assert_response :not_found
    end

    test "keeps professionals and places inside Percorso Integrato" do
      get percorso_integrato_professionals_path
      assert_response :success
      assert_select "h1", text: "Professionisti del Percorso Integrato"
      assert_select "a[href='#{percorso_integrato_professional_path('giovanni-damiata')}']"
      assert_select "a[href='#{percorso_integrato_professional_path('davide-cattaneo')}']"

      get percorso_integrato_professional_path("giovanni-damiata")
      assert_response :success
      assert_select "h1", text: "Giovanni Damiata"

      get percorso_integrato_professional_path("davide-cattaneo")
      assert_response :success
      assert_select "h1", text: "Davide Cattaneo"
      assert_select "img[alt='Foto profilo di Davide Cattaneo']"
      assert_select "nav[aria-label='Sezioni del profilo professionale']" do
        assert_select "a[href='#{percorso_integrato_professional_path("davide-cattaneo", tab: "profilo")}']", text: /Profilo/
        assert_select "a[href='#{percorso_integrato_professional_path("davide-cattaneo", tab: "servizi")}']", text: /Servizi/
        assert_select "a[href='#{percorso_integrato_professional_path("davide-cattaneo", tab: "formazione")}']", text: /Formazione/
        assert_select "a[href='#{percorso_integrato_professional_path("davide-cattaneo", tab: "contenuti")}']", text: /Contenuti/
      end
      assert_select "a[href='#{posturacorretta_insegnante_path("davide-cattaneo")}']", text: /Profilo insegnante/

      get percorso_integrato_professional_path("davide-cattaneo", tab: "servizi")
      assert_response :success
      assert_select "h2", text: "Servizi e percorsi"
      assert_select "h3", text: "Lezioni di nuoto"
      assert_select "h3", text: "Trattamento benessere"

      get percorso_integrato_professional_path("davide-cattaneo", tab: "formazione")
      assert_response :success
      assert_select "h2", text: "Formazione e attestati"
      assert_select "a[href='https://ik.imagekit.io/posturacorretta/corsi/igiene_posturale/attestati_insegnanti_igiene_posturale/01-davide-cattaneo-cert-igp-2025-08-12.png']"

      get percorso_integrato_professional_path("davide-cattaneo", tab: "contenuti")
      assert_response :success
      assert_select "h2", text: "Video, schede e contenuti"
      assert_select "a[href='https://youtube.com/watch?v=FthfIMTv7CQ']"
      assert_select "a[href='#{percorso_integrato_professional_material_path("davide-cattaneo", "scheda-nuoto")}']", text: /Preparazione al nuoto · 10 esercizi/

      get percorso_integrato_professional_material_path("davide-cattaneo", "scheda-nuoto")
      assert_response :success
      assert_select "h1", text: "Preparazione al nuoto · 10 esercizi"
      assert_select "table tbody tr", count: 10
      assert_select "a[href='#{percorso_integrato_professional_exercise_path("davide-cattaneo", "scheda-nuoto", 1)}']"

      get percorso_integrato_professional_exercise_path("davide-cattaneo", "scheda-nuoto", 1)
      assert_response :success
      assert_select "h1", text: "Allungamento in alto"
      assert_select "a[href='#{percorso_integrato_professional_exercise_path("davide-cattaneo", "scheda-nuoto", 2)}']", text: /Successivo/

      get percorso_integrato_professional_material_image_path("davide-cattaneo", "scheda-nuoto", 1)
      assert_response :success
      assert_equal "image/gif", response.media_type

      get percorso_integrato_places_path
      assert_response :success
      assert_select "h1", text: "Centri del Percorso Integrato"
      assert_select "h2", text: "Sede PosturaCorretta · Cascina Bordonala"
      assert_select "h2", text: "Studio Movimento"
      assert_select "h2", text: "Giardino del Corpo", count: 0

      get percorso_integrato_services_path
      assert_response :success
      assert_select "h1", text: "Servizi del Percorso Integrato"

      get percorso_integrato_municipalities_path
      assert_response :success
      assert_select "h1", text: "Comuni del Percorso Integrato"
      assert_select "h2", text: "Comune di Calvisano"

      get percorso_integrato_municipality_path("calvisano")
      assert_response :success
      assert_select "h1", text: /Calvisano/
      assert_select "#mappa"
      assert_select "#filtri-stato"
      assert_select "#tab-professionisti"
      assert_select "#tab-gruppi"
      assert_select "#tab-domicilio"
      assert_select "#tab-eventi"

      get percorso_integrato_municipality_professionals_path("calvisano")
      assert_response :success
      assert_select "h1", text: /Strutture libere e spazi operativi a Calvisano/
      assert_select "h2", text: "Studio Trattamenti & Colloqui Clinici"
    end
  end
end
