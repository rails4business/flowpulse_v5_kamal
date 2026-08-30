require "test_helper"

class PosturacorrettaHomeEcosystemTest < ActionDispatch::IntegrationTest
  test "three projects page preserves the former home ecosystem" do
    get "/posturacorretta/tre-progetti"

    assert_response :success
    assert_select "h1", text: /Tre modi per conoscere, curare e coltivare l’essere umano/
    assert_select "article", count: 3
    assert_select "a[href='/posturacorretta/primo-mese']", text: /Inizia PosturaCorretta in un mese/
    assert_select "a[href='/percorso-integrato']", text: /Scopri il Percorso Integrato/
    assert_select "a[href='/giardino-del-corpo']", text: /Scopri Il Giardino del Corpo/
    assert_select "p", text: "La persona"
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
  end

  test "standalone integrated path ends with the shared three projects chapter" do
    get "/percorso-integrato"

    assert_response :success
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
    assert_select "a[aria-current='page'][href='/percorso-integrato']", text: /Percorso Integrato/
  end

  test "garden ends with the shared three projects chapter" do
    get "/giardino-del-corpo"

    assert_response :success
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
    assert_select "a[aria-current='page'][href='/giardino-del-corpo']", text: /Il Giardino del Corpo/
  end
end
