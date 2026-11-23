require "test_helper"

class RadioestesiaControllerTest < ActionDispatch::IntegrationTest
  test "renders all preview pages without indexing" do
    [
      "/generaimpresa/brand/radioestesia",
      "/generaimpresa/brand/radioestesia/chi-sono",
      "/generaimpresa/brand/radioestesia/percorsi",
      "/generaimpresa/brand/radioestesia/contatti",
      "/generaimpresa/brand/radioestesia/contenuti",
      "/generaimpresa/brand/radioestesia/eventi"
    ].each do |path|
      get path

      assert_response :success
      assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    end
  end

  test "home mirrors the current site with a free call booking" do
    get "/generaimpresa/brand/radioestesia"

    assert_select "h1", "La Radiestesia al servizio del tuo Benessere"
    assert_select "p", /Radiestesia e Nutrizione energetica entrano in sinergia/
    assert_select "a[href='/generaimpresa/brand/radioestesia/percorsi']", /Scopri di più/
    assert_select "a[href='https://calendly.com/elisa-corubolo/30min']", /Prenota una call gratuita/
    assert_select "footer", /P\. IVA: 03185790304/
    assert_select "#pannello-superadmin", count: 0
  end

  test "home gathers everything to update in a superadmin-only panel" do
    user = User.create!(
      email_address: "radioestesia-confermare@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    user.create_profile!(display_name: "Radioestesia Confermare")
    post session_url, params: { email_address: user.email_address, password: "password123" }

    get "/generaimpresa/brand/radioestesia"

    assert_select "#pannello-superadmin a[href='/generaimpresa/brand/radioestesia/changelog']"
    assert_select "#da-fare li", /pagina show degli eventi/
    assert_select "#da-confermare", /elisa@radiestesiaebenessere.com/
    assert_select "#proposta-prezzi tbody tr", 11
    assert_select "#registro-ore", /totale 8 h/
    assert_select "#registro-ore", /23\/11\/2026 · 4 h/
    assert_select "#registro-ore", /25\/09\/2026 · 4 h/

    get "/generaimpresa/brand/radioestesia/percorso-evoluzione-personale"

    assert_select "#proposta-prezzi", count: 0
  end

  test "chi sono presents Elisa with portrait, diploma and link to percorsi" do
    get "/generaimpresa/brand/radioestesia/chi-sono"

    assert_select "p", /GRATA CHE TU SIA QUI!/
    assert_select "p", /Elisa Corubolo, professionista in Radiestesia/
    assert_select "img[alt='Ritratto di Elisa, fondatrice di Armonia']"
    assert_select "figcaption", /Radiestesia avanzata e Radionica/
    assert_select "a[href='/generaimpresa/brand/radioestesia/percorsi']", /Scopri le mie proposte per te/
  end

  test "percorsi lists the three paths in the current site order" do
    get "/generaimpresa/brand/radioestesia/percorsi"

    assert_select "h1", "Percorsi di radiestesia per il riequilibrio energetico e il benessere interiore"
    assert_select "article h3", count: 3
    assert_select "article:first-child h3", "1. NUTRIZIONE ENERGETICA"
    assert_select "article", /gonfiore, stanchezza, fame emotiva/
    assert_select "a[href='/generaimpresa/brand/radioestesia/contatti']", /Contattami/
    assert_select "a[href='/generaimpresa/brand/radioestesia/mappa-energetica-degli-alimenti']", /Scopri di più/
    assert_select "a[href='/generaimpresa/brand/radioestesia/riequilibrio-radiestesico']", /Scopri di più/
    assert_select "a[href='/generaimpresa/brand/radioestesia/rimozione-blocchi-e-credenze-limitanti']", /Scopri di più/
  end

  test "percorsi links the personal growth journey built from its course list" do
    get "/generaimpresa/brand/radioestesia/percorsi"

    assert_select "a[href='/generaimpresa/brand/radioestesia/percorso-evoluzione-personale']", /alla scoperta dei tuoi aspetti energetici/

    get "/generaimpresa/brand/radioestesia/percorso-evoluzione-personale"

    assert_response :success
    assert_select "h1", "Impara a percepire i tuoi aspetti energetici"
    assert_select "p", /può affiancare, ma non sostituisce, diagnosi, terapie o cure mediche/
    corsi = YAML.load_file(Rails.root.join("docs/radiestesiaebenessere/percorso_radioestesia.yaml")).dig("percorso", "corsi")
    assert_select "article > ol > li", corsi.size
    assert_select "h2", /Il nostro orologio biologico/
    assert_select "li", /meridiano del Fegato/
    assert_select "details li > p > span", text: "In preparazione · da programmare", count: corsi.sum { |corso| corso.fetch("lezioni").size }
  end

  test "path detail pages show text, testimonials and contact button" do
    get "/generaimpresa/brand/radioestesia/mappa-energetica-degli-alimenti"

    assert_select "h1", "Mappa energetica degli alimenti"
    assert_select "li", /analisi energetica di 60, 100 o 150 alimenti/
    assert_select "figcaption", "ANNA Z."

    get "/generaimpresa/brand/radioestesia/riequilibrio-radiestesico"

    assert_select "h1", "Riequilibrio Radiestesico Clinico"
    assert_select "ol li", 2
    assert_select "figcaption", "GIADA F."

    get "/generaimpresa/brand/radioestesia/rimozione-blocchi-e-credenze-limitanti"

    assert_select "h1", "Rimozione dei blocchi e delle credenze limitanti"
    assert_select "figcaption", "STEFANIA C."
    assert_select "a[href='/generaimpresa/brand/radioestesia/contatti']", /Contattami/
  end

  test "contatti lists whatsapp, email, instagram and the free call" do
    get "/generaimpresa/brand/radioestesia/contatti"

    assert_select "h1", "CONTATTAMI:"
    assert_select "a[href='https://wa.me/393520225930']", /\+39 352 022 5930/
    assert_select "a[href='mailto:elisa.corubolo@outlook.it']", /elisa.corubolo@outlook.it/
    assert_select "a[href='https://www.instagram.com/elisa.armonia']", /@elisa.armonia/
    assert_select "a[href='https://calendly.com/elisa-corubolo/30min']", /Prenota la tua call gratuita/  end

  test "renders a free chapter with the course sidebar" do
    get "/generaimpresa/brand/radioestesia/contenuti/mappa-energetica-alimenti"

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "h1", "Mappa energetica degli alimenti"
    assert_select ".markdown-content", /Cosa troverai/
    assert_select "aside", /Materiali di conferenze/
  end

  test "shows item purchase and annual options for a future masterclass" do
    travel_to Time.zone.parse("2026-09-10 09:00") do
      get "/generaimpresa/brand/radioestesia/contenuti/incontro-di-approfondimento"

      assert_response :success
      assert_select "#acquista", /Partecipa alla masterclass/
      assert_select "#acquista", /€111/
      assert_select "#acquista", /€79/
      assert_select "#acquista", /€88,80/
      assert_select "#acquista", /€167,80/
      assert_select "#acquista", /20% di sconto/
    end
  end

  test "lists upcoming events and published contents on two separate pages" do
    travel_to Time.zone.parse("2026-09-10 09:00") do
      get "/generaimpresa/brand/radioestesia/eventi"

      assert_response :success
      assert_select "h1", "Eventi"
      assert_select "a", /Prepara la tua energia all’Autunno/
      assert_select "a", /Online · 09:00–11:00/
      assert_select "[role='tablist']", count: 0
      assert_select "a", text: /Mappa energetica degli alimenti/, count: 0
      assert_select "a", text: /Materiali di conferenze/, count: 0

      get "/generaimpresa/brand/radioestesia/contenuti"

      assert_response :success
      assert_select "h1", "Contenuti"
      assert_select "a", /Introduzione alla radiestesia/
      assert_select "a", /Pratiche di ascolto quotidiano/
      assert_select "a", text: /Prepara la tua energia all’Autunno/, count: 0
    end
  end

  test "nav lists contenuti and eventi before contatti, and old tab links redirect" do
    get "/generaimpresa/brand/radioestesia"

    labels = css_select("nav[aria-label='Navigazione Radioestesia'] a").map { |link| link.text.strip }
    assert_equal %w[Home Chi\ sono Percorsi Contenuti Eventi Contatti], labels

    get "/generaimpresa/brand/radioestesia/contenuti?tab=eventi"
    assert_redirected_to "/generaimpresa/brand/radioestesia/eventi"
  end

  test "redirects the old FlowPulse and PosturaCorretta preview paths" do
    get "/flowpulse/radioestesia"
    assert_redirected_to "/generaimpresa/brand/radioestesia"

    get "/flowpulse/radioestesia/contenuti/mappa-energetica-alimenti"
    assert_redirected_to "/generaimpresa/brand/radioestesia/contenuti/mappa-energetica-alimenti"

    get "/posturacorretta/radioestesia"
    assert_redirected_to "/generaimpresa/brand/radioestesia"

    get "/posturacorretta/radioestesia/contenuti/mappa-energetica-alimenti"
    assert_redirected_to "/generaimpresa/brand/radioestesia/contenuti/mappa-energetica-alimenti"
  end
end
