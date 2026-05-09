require "test_helper"

class PublicEventsControllerTest < ActionDispatch::IntegrationTest
  test "should show eventi tab by default inside esperienze page" do
    get eventi_url
    assert_response :success
    assert_includes response.body, "Postura in Vetta"
    assert_includes response.body, "Avventure"
    assert_includes response.body, "Esperienze"
    assert_includes response.body, "Evento · 1 giornata"
    assert_includes response.body, "Seminario · 3 serate"
    assert_includes response.body, "/eventi?tab=eventi"
    assert_includes response.body, "/eventi?tab=servizi"
    assert_includes response.body, "/eventi?tab=corsi"
  end

  test "should show avventure tab" do
    get eventi_url(tab: "avventure")
    assert_response :success
    assert_includes response.body, "Alba fuori rotta"
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
end
