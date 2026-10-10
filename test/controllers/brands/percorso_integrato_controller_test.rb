require "test_helper"

module Brands
  class PercorsoIntegratoControllerTest < ActionDispatch::IntegrationTest
    test "shows the standalone Percorso Integrato brand" do
      get percorso_integrato_path

      assert_response :success
      assert_select "h1", text: "Costruisci un percorso personale, leggibile e coordinato."
      assert_select "nav[aria-label='Navigazione Percorso Integrato']"
      assert_select "header img[src*='percorso_integrato_vecchio.png']"
      assert_select "nav[aria-label='Navigazione Percorso Integrato'] a", text: "Docs"
      assert_select "a[href='#{percorso_integrato_docs_path}']", text: "Apri le Docs"
      assert_select "a.pi-button.pi-button--primary", minimum: 3
      assert_select "a.pi-button.pi-button--secondary", text: "Apri le Docs"
      assert_select "#come-funziona"
      assert_select "#percorso"
      assert_select "#percorso .pi-upgrade__level", count: 7
      assert_select "#percorso", text: /Salute a rischio/
      assert_select "#percorso", text: /Connessione/
      assert_select "details.pi-upgrade__deep"
      assert_select "#ruoli"
      assert_select "#inizia"
      assert_select "a[href^='https://wa.me/393792891488']", text: "Scrivi su WhatsApp"
    end

    test "redirects the former PosturaCorretta path to the standalone brand" do
      get posturacorretta_percorso_path

      assert_redirected_to percorso_integrato_path
      assert_response :moved_permanently
    end

    test "shows its own docs and redirects the former PosturaCorretta guide section" do
      get percorso_integrato_docs_path

      assert_response :success
      assert_select "article", text: /Il Percorso Integrato aiuta a partire da bisogni e obiettivi concreti/
      assert_select ".editorial-rich-text.editorial-rich-text--emerald"
      assert_select "nav[aria-label='Navigazione Percorso Integrato'] a", text: "PosturaCorretta", count: 0

      get posturacorretta_guida_path(sezione: "percorso")

      assert_response :moved_permanently
      assert_redirected_to percorso_integrato_docs_path

      get posturacorretta_guida_path(sezione: "percorso", capitolo: "professionisti-iniziare-percorso")

      assert_response :moved_permanently
      assert_redirected_to percorso_integrato_docs_path(doc: "iniziare-percorso")

      get percorso_integrato_docs_path(doc: "scegli-programma")

      assert_response :success
      assert_select "h1", text: "Parti dal bisogno che senti più vicino."
      assert_select "a.pi-button.pi-button--primary", text: "Chiedi orientamento su WhatsApp"
      assert_select "a[href^='/posturacorretta']", count: 0
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
      assert_select "h1", text: "Luoghi del Percorso Integrato"
      assert_select "h2", text: "Sede PosturaCorretta · Cascina Bordonala"
      assert_select "p", text: "Viadana di Calvisano · Brescia"
      assert_select "h2", text: "Studio Movimento"
      assert_select "h2", text: "Giardino del Corpo", count: 0
    end
  end
end
