require "test_helper"

class GeneraImpresaControllerTest < ActionDispatch::IntegrationTest
  test "renders the public brand and project catalog" do
    get genera_impresa_url
    assert_response :success
    assert_select "h1", /Dalle idee ai progetti/
    assert_includes response.body, "PosturaCorretta"
    assert_includes response.body, "Flowpulse"
  end

  test "renders a brand with many projects" do
    get genera_impresa_brand_url("posturacorretta")
    assert_response :success
    assert_select "h1", "PosturaCorretta"
    assert_select "h2", "Progetti del brand"
  end

  test "renders a brand with one project" do
    get genera_impresa_brand_url("flowpulse")
    assert_response :success
    assert_select "h1", "Flowpulse"
    assert_select "article", count: 1
  end

  test "renders SvuotaMente as a brand with its webapp project" do
    get genera_impresa_brand_url("svuotamente")
    assert_response :success
    assert_select "h1", "SvuotaMente"
    assert_includes response.body, "Webapp SvuotaMente"

    get genera_impresa_project_url("webapp-svuotamente")
    assert_response :success
    assert_select "a[href=?]", svuotamente_path, text: /Apri la webapp/
  end

  test "renders a public project page" do
    get genera_impresa_project_url("piattaforma-flowpulse-rails4business")
    assert_response :success
    assert_includes response.body, "Step del progetto"
  end
end
