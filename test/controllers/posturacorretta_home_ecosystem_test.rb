require "test_helper"

class PosturacorrettaHomeEcosystemTest < ActionDispatch::IntegrationTest
  test "three projects page preserves the former home ecosystem" do
    get "/posturacorretta/tre-progetti"

    assert_response :success
    assert_select "h1", text: /Postura Salute e Stile di vita!/
    assert_select "article", count: 3
    assert_select "a[href='/posturacorretta']", text: /Scopri PosturaCorretta/
    assert_select "a[href='/percorso-integrato']", text: /Crea il tuo percorso su misura/
    assert_select "a[href='/il-giardino-del-corpo']", text: /Scopri la filosofia e gli eventi/
  end

  test "standalone integrated path ends with the shared three projects chapter" do
    get "/percorso-integrato"

    assert_response :success
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
    assert_select "a[aria-current='page'][href='/percorso-integrato']", text: /Percorso Integrato/
  end

  test "garden ends with the shared three projects chapter" do
    get "/il-giardino-del-corpo"

    assert_response :success
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
    assert_select "a[aria-current='page'][href='/il-giardino-del-corpo']", text: /Il Giardino del Corpo/
  end
end
