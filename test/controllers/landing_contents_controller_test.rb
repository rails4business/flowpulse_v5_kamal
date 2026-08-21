require "test_helper"

class LandingContentsControllerTest < ActionDispatch::IntegrationTest
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
    assert_match "Come possiamo costruire un'alternativa", response.body
    assert_match "@markpostura", response.body
  end
end
