require "test_helper"

class LandingContentsControllerTest < ActionDispatch::IntegrationTest
  test "shows Flowpulse contents and a working events action on the landing page" do
    get flowpulse_path

    assert_response :success
    assert_select "img[src='https://ik.imagekit.io/posturacorretta/flowpulse-ilgdc-21-08-2026.png']", count: 1
    assert_select "a[href='#{eventi_path}']", text: "Organizza un evento", count: 1
    assert_select "a[href='/flowpulse/contenuti/costruire-un-sistema-economico-nuovo']", count: 1
    assert_select "a[href='/flowpulse/contenuti/dalla-moneta-alla-comunita-economia-circolare-dash']", count: 1
  end

  test "shows contents attributed to markpostura across domains" do
    get markpostura_contents_path

    assert_response :success
    assert_select "h1", text: "Contenuti"
    assert_select "a[href*='posturacorretta.org/posturacorretta/contenuti/']", minimum: 1
    assert_select "a[href='https://flowpulse.net/flowpulse/contenuti/costruire-un-sistema-economico-nuovo']", count: 1
    assert_match "@markpostura", response.body
  end

  test "shows a Flowpulse markdown article" do
    get flowpulse_content_path("costruire-un-sistema-economico-nuovo")

    assert_response :success
    assert_select "h1", text: "È possibile costruire un sistema economico nuovo senza diventare fuorilegge?", count: 1
    assert_select "article.editorial-rich-text.editorial-rich-text--violet", count: 1
    assert_match "Come possiamo costruire un'alternativa", response.body
    assert_match "@markpostura", response.body
  end

  test "shows the Flowpulse contents index" do
    get flowpulse_contents_path

    assert_response :success
    assert_select "h1", text: "Contenuti Flowpulse"
    assert_select "a[href='/flowpulse/contenuti/costruire-un-sistema-economico-nuovo']", count: 1
    assert_match "@markpostura", response.body
    assert_match "21/08/2026", response.body
  end

  test "shows events organized by markpostura without duplicating their source" do
    get markpostura_events_path

    assert_response :success
    assert_select "h1", text: "Prossimi eventi"
    assert_select "a[href='https://posturacorretta.org/posturacorretta/eventi']", minimum: 1
    assert_match "PosturaCorretta", response.body
  end

  test "renders a dated PosturaCorretta markdown article without changing its slug" do
    get posturacorretta_articolo_path("metodiche-posturali-e-fisiologia")

    assert_response :success
    assert_select "article.editorial-rich-text.editorial-rich-text--blue", count: 1
    assert_match "L'importanza dell'ascolto", response.body
  end
end
