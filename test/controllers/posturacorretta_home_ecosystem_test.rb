require "test_helper"

class PosturacorrettaHomeEcosystemTest < ActionDispatch::IntegrationTest
  test "home presents the person and the three complementary projects" do
    get "/posturacorretta"

    assert_response :success
    assert_select "h1", text: /Tre modi per conoscere, curare e coltivare l’essere umano/
    assert_select "article", count: 3
    assert_select "a[href='/posturacorretta/primo-mese']", text: /Inizia PosturaCorretta in un mese/
    assert_select "a[href='/posturacorretta/percorso']", text: /Scopri il Percorso Integrato/
    assert_select "a[href='/giardino-del-corpo']", text: /Scopri Il Giardino del Corpo/
    assert_select "p", text: "La persona"
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
  end

  test "integrated path ends with the shared three projects chapter" do
    get "/posturacorretta/percorso"

    assert_response :success
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
    assert_select "a[aria-current='page'][href='/posturacorretta/percorso']", text: /Percorso Integrato/
  end

  test "garden ends with the shared three projects chapter" do
    get "/giardino-del-corpo"

    assert_response :success
    assert_select "#three-projects-title", text: "Tre progetti, una persona."
    assert_select "a[aria-current='page'][href='/giardino-del-corpo']", text: /Il Giardino del Corpo/
  end
end
