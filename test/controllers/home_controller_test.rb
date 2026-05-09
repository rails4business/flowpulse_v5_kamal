require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_index_url
    assert_response :success
  end

  test "root should open mari" do
    get root_url
    assert_response :success
    assert_includes response.body, "/viste_html/0_mari.html?mare=salute"
    assert_includes response.body, eventi_path
    assert_includes response.body, progetti_path
    assert_includes response.body, root_path
  end

  test "should get progetti page" do
    get progetti_url
    assert_response :success
    assert_includes response.body, "Scopri i progetti, seguili, sostienili o unisciti al team"
    assert_includes response.body, "Accademia Postura Corretta"
  end

  test "should get lavoro dashboard page" do
    get lavoro_url
    assert_response :success
    assert_includes response.body, "Creator, professionisti, attitudini, ruoli e servizi"
    assert_includes response.body, "Creator"
    assert_includes response.body, "Professionisti"
    assert_includes response.body, "Ruolo"
  end

  test "should get salute dashboard" do
    get salute_url
    assert_response :success
    assert_includes response.body, "Percorsi"
    assert_includes response.body, "Corsi"
    assert_includes response.body, view_page_path("percorsi-salute")
    assert_includes response.body, view_page_path("corsi-salute")
  end

  test "should get registered view page" do
    get view_page_url("evento-costi-ruoli")
    assert_response :success
    assert_includes response.body, "title=\"Evento costi e ruoli\""
    assert_includes response.body, "/viste_html/evento_costi_ruoli.html"
  end

  test "should redirect dashboard when not authenticated" do
    get dashboard_url
    assert_redirected_to new_session_url
  end

  test "should get dashboard for authenticated non superadmin" do
    user = User.create!(
      email_address: "dashboard@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get dashboard_url

    assert_response :success
    assert_includes response.body, "Strumenti interni"
    assert_includes response.body, "Disponibile quando sbloccato dal superadmin"
  end

  test "should show unlocked dashboard navigation for superadmin" do
    user = User.create!(
      email_address: "superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true
    )

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get lavoro_url

    assert_response :success
    assert_includes response.body, dashboard_path
    assert_includes response.body, resources_path
    assert_not_includes response.body, "Disponibile quando sbloccato dal superadmin"
  end

  test "should get eventi page" do
    get eventi_url
    assert_response :success
    assert_includes response.body, "Pronte per nuove aperture"
    assert_includes response.body, ">Esperienze<"
    assert_includes response.body, evento_path(1)
  end

  test "should get elenco pagine" do
    get elenco_pagine_url
    assert_response :success
    assert_includes response.body, "Pagine con controller"
  end
end
