require "test_helper"

class PublicEventsControllerTest < ActionDispatch::IntegrationTest
  test "should show eventi tab by default inside esperienze page" do
    get esperienze_url
    assert_response :success
    assert_includes response.body, "Postura in Vetta"
    assert_includes response.body, "Percorsi"
    assert_includes response.body, "Contenuti"
    assert_includes response.body, "Esperienze"
    assert_includes response.body, "PosturaCorretta in vetta"
    assert_includes response.body, "Inside Adventure Lab"
    assert_includes response.body, "/esperienze?tab=eventi"
    assert_includes response.body, "/esperienze?tab=servizi"
    assert_includes response.body, "/esperienze?tab=corsi"
  end

  test "should show percorsi tab" do
    get esperienze_url(tab: "percorsi")
    assert_response :success
    assert_includes response.body, "Schiena Sana 360"
  end

  test "should show servizi tab" do
    get esperienze_url(tab: "servizi")
    assert_response :success
    assert_includes response.body, "Valutazione posturale guidata"
    assert_includes response.body, "Singolo"
    assert_includes response.body, "80€"
  end

  test "should show public event detail" do
    get esperienza_url(1)
    assert_response :success
    assert_includes response.body, "Postura in Vetta"
  end
end
