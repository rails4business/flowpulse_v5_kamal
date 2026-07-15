require "test_helper"

class PosturacorrettaControllerTest < ActionDispatch::IntegrationTest
  test "should get accademia (landing page)" do
    get posturacorretta_url
    assert_response :success
    assert_includes response.body, "Accademia"
  end

  test "should get percorso" do
    get posturacorretta_percorso_url
    assert_response :success
    assert_includes response.body, "Costruisci"
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

  test "should get filosofia" do
    get posturacorretta_filosofia_url
    assert_response :success
    assert_includes response.body, "Libro e Visione"
  end

  test "should get collabora" do
    get posturacorretta_collabora_url
    assert_response :success
    assert_includes response.body, "Progetti in corso"
  end
end
