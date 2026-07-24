require "test_helper"

class PosturacorrettaControllerTest < ActionDispatch::IntegrationTest
  test "should get accademia (landing page)" do
    get posturacorretta_url
    assert_response :success
    assert_includes response.body, "Accademia"
  end

  test "should get dedicated accademia page" do
    get posturacorretta_accademia_url
    assert_response :success
    assert_includes response.body, "Accademia"
  end

  test "should get percorso" do
    get posturacorretta_percorso_url
    assert_response :success
    assert_includes response.body, "Costruisci"
  end

  test "should get metodiche index" do
    get posturacorretta_metodiche_url
    assert_response :success
    assert_includes response.body, "Archivio metodiche"
    assert_includes response.body, "Biomeccanica Comportamentale GDS"
  end

  test "should get metodica show" do
    get posturacorretta_metodica_url("gds")
    assert_response :success
    assert_includes response.body, "Godelieve Denys-Struyf"
    assert_includes response.body, "Professionisti collegati"
  end

  test "should get contenuti" do
    get posturacorretta_contenuti_url
    assert_response :success
    assert_includes response.body, "PosturaCorretta Blog"
  end

  test "should get eventi" do
    get posturacorretta_eventi_url
    assert_response :success
    assert_includes response.body, "Eventi e Community"
  end

  test "should get libro" do
    get posturacorretta_libro_url
    assert_response :success
    assert_includes response.body, "Libro e Visione"
  end

  test "filosofia redirects to libro" do
    get posturacorretta_filosofia_url
    assert_redirected_to posturacorretta_libro_url
  end

  test "collabora redirects to progetti" do
    get posturacorretta_collabora_url
    assert_redirected_to posturacorretta_progetti_url
  end

  test "should get progetti" do
    get posturacorretta_progetti_url
    assert_response :success
    assert_includes response.body, "Progetti"
  end

  test "should get progetto by slug" do
    get posturacorretta_progetto_url("accademia-posturacorretta")
    assert_response :success
    assert_includes response.body, "Accademia PosturaCorretta"
  end

  test "missing progetto redirects to index" do
    get posturacorretta_progetto_url("progetto-inesistente")
    assert_redirected_to posturacorretta_progetti_url
  end
end
