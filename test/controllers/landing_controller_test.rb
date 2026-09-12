require "test_helper"

class LandingControllerTest < ActionDispatch::IntegrationTest
  test "Rails4Business landing renders both current logo assets" do
    get rails4b_url

    assert_response :success
    assert_select "img[src*='rails4b_logo_quadrato']"
    assert_select "img[src*='rails4b_logo_lungo']", count: 0
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "guarda-flowpulse")}']", text: /Guarda Flowpulse/
    assert_select "a[href='#{rails4b_path(percorso: "collaborare")}']", text: /Voglio collaborare/
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

  test "Rails4Business separates dated content from the permanent train" do
    get rails4b_contents_url

    assert_response :success
    assert_select "h1", text: "Contenuti Rails4Business"
    assert_select "a[href='#{rails4b_contents_path(tab: "prossimi")}']", text: "Prossimi"
    assert_select "a[href='#{rails4b_contents_path(tab: "passati")}']", text: "Passati"
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "installa-dash-wallet")}']", text: /Installa Dash Wallet/
  end

  test "Rails4Business switches to the collaboration train" do
    get rails4b_url(percorso: "collaborare")

    assert_response :success
    assert_select "h3", text: "Guarda Flowpulse"
    assert_select "a[href='#{rails4b_track_path("collaborare", contenuto: "guarda-flowpulse")}']", text: /Guarda Flowpulse/
  end

  test "Rails4Business renders a track show with its content aside" do
    get rails4b_track_url("collaborare", contenuto: "guarda-flowpulse")

    assert_response :success
    assert_select "aside", text: /Installa Dash Wallet/
    assert_select "h1", text: "Guarda Flowpulse"
  end
end
