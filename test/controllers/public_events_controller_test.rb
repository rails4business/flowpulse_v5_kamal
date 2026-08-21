require "test_helper"

class PublicEventsControllerTest < ActionDispatch::IntegrationTest
  test "should show eventi tab by default" do
    get eventi_url
    assert_response :success
    assert_includes response.body, "Postura in Vetta"
    assert_includes response.body, "Percorsi"
    assert_includes response.body, "Contenuti"
    assert_includes response.body, "Eventi"
    assert_includes response.body, "PosturaCorretta in vetta"
    assert_includes response.body, "Inside Adventure Lab"
    assert_includes response.body, "/eventi?tab=eventi"
    assert_includes response.body, "/eventi?tab=servizi"
    assert_includes response.body, "/eventi?tab=corsi"
  end

  test "should show percorsi tab" do
    get eventi_url(tab: "percorsi")
    assert_response :success
    assert_includes response.body, "Schiena Sana 360"
  end

  test "should show servizi tab" do
    get eventi_url(tab: "servizi")
    assert_response :success
    assert_includes response.body, "Valutazione posturale guidata"
    assert_includes response.body, "Singolo"
    assert_includes response.body, "80€"
  end

  test "should show public event detail" do
    get evento_url(1)
    assert_response :success
    assert_includes response.body, "Postura in Vetta"
  end

  test "should redirect legacy experience URLs to eventi" do
    get esperienze_url
    assert_redirected_to eventi_url

    get esperienza_url(1)
    assert_redirected_to evento_url(1)
  end
end
