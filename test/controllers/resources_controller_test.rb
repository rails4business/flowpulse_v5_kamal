require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "should get resources index with tabs" do
    get resources_url
    assert_response :success
    assert_includes response.body, "Materiali, transazioni, contatti, abilita ed energia"
    assert_includes response.body, "Eventi"
    assert_includes response.body, "Transazioni"
    assert_includes response.body, "Attenzione"
  end

  test "should switch to abilita tab" do
    get resources_url(tab: "abilita")
    assert_response :success
    assert_includes response.body, "Valutazione mobilita articolare"
  end

  test "should get resource detail" do
    get resource_url(10)
    assert_response :success
    assert_includes response.body, "Riparto evento Postura in Vetta"
    assert_includes response.body, "Torna a risorse"
  end
end
