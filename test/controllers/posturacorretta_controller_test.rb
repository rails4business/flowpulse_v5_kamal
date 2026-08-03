require "test_helper"

class PosturacorrettaControllerTest < ActionDispatch::IntegrationTest
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
  end

  test "should get contenuti" do
    get posturacorretta_contenuti_url
    assert_response :success
    assert_includes response.body, "Contenuti"
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
