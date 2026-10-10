require "test_helper"

class RadioestesiaControllerTest < ActionDispatch::IntegrationTest
  test "renders all preview pages without indexing" do
    [
      "/generaimpresa/brand/radioestesia",
      "/generaimpresa/brand/radioestesia/chi-sono",
      "/generaimpresa/brand/radioestesia/percorsi",
      "/generaimpresa/brand/radioestesia/contatti",
      "/generaimpresa/brand/radioestesia/contenuti"
    ].each do |path|
      get path

      assert_response :success
      assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    end
  end

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

  test "lists independent entries through shareable events and contents tabs" do
    travel_to Time.zone.parse("2026-09-10 09:00") do
      get "/generaimpresa/brand/radioestesia/contenuti?tab=eventi"

      assert_response :success
      assert_select "a", /Prepara la tua energia all’Autunno/
      assert_select "a", /Online · 09:00–11:00/
      assert_select "a[href*='tab=contenuti']", /Contenuti/
      assert_select "a", text: /Scopri l'accesso annuale/, count: 0
      assert_select "p", text: /L'ascolto di sé è il primo passo/, count: 0
      assert_select "a", text: /Mappa energetica degli alimenti/, count: 0
      assert_select "a", text: /Materiali di conferenze/, count: 0

      get "/generaimpresa/brand/radioestesia/contenuti?tab=contenuti"

      assert_response :success
      assert_select "a", /Introduzione alla radiestesia/
      assert_select "a", /Pratiche di ascolto quotidiano/
      assert_select "a", text: /Prepara la tua energia all’Autunno/, count: 0
    end
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
