require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "root should respond" do
    get root_url

    assert_response :success
  end

  test "root should expose public experiences" do
    get root_url

    assert_response :success
    assert_includes response.body, esperienze_path
    assert_includes response.body, root_path
    assert_not_includes response.body, 'data-layout="dashboard"'
    assert_not_includes response.body, "data-dashboard-sidebar"
  end

  test "demo user should get progetti page" do
    sign_in(create_user("demo-progetti@example.com", demo_access: true, active_role: :demo))

    get demo_progetti_url

    assert_response :success
    assert_includes response.body, "Scopri i progetti, seguili, sostienili o unisciti al team"
    assert_includes response.body, "Accademia Postura Corretta"
  end

  test "demo user should get lavoro dashboard page" do
    sign_in(create_user("demo-lavoro@example.com", demo_access: true, active_role: :demo))

    get demo_lavoro_url

    assert_response :success
    assert_includes response.body, "Creator, professionisti, attitudini, ruoli e servizi"
    assert_includes response.body, "Creator"
    assert_includes response.body, "Professionisti"
    assert_includes response.body, "Ruolo"
  end

  test "demo user should get salute dashboard" do
    sign_in(create_user("demo-salute@example.com", demo_access: true, active_role: :demo))

    get demo_salute_url

    assert_response :success
    assert_includes response.body, "Percorsi"
    assert_includes response.body, "Corsi"
    assert_includes response.body, demo_view_page_path("corsi-salute")
  end

  test "registered demo view page requires demo access" do
    get demo_view_page_url("evento-costi-ruoli")

    assert_redirected_to new_session_url
  end

  test "demo user should get registered view page" do
    sign_in(create_user("demo-view-page@example.com", demo_access: true, active_role: :demo))

    get demo_view_page_url("evento-costi-ruoli")

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

    assert_redirected_to viaggiatori_url
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Dashboard Viaggiatore"
  end

  test "should show unlocked dashboard navigation for superadmin" do
    user = User.create!(
      email_address: "superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    user.create_profile!(display_name: "Superadmin")

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get demo_lavoro_url

    assert_response :success
    assert_includes response.body, dashboard_path
    assert_includes response.body, admin_risorse_index_path
    assert_not_includes response.body, "Disponibile quando sbloccato dal superadmin"
  end

  test "should get esperienze page" do
    get esperienze_url
    assert_response :success
    assert_includes response.body, "Cosa vuoi fare oggi?"
    assert_includes response.body, ">Esperienze<"
    assert_includes response.body, esperienza_path(1)
  end

  test "should get elenco pagine" do
    sign_in(create_user("elenco-pagine-superadmin@example.com", superadmin: true, active_role: :superadmin))

    get admin_elenco_pagine_url

    assert_response :success
    assert_includes response.body, 'data-layout="dashboard"'
    assert_includes response.body, "data-dashboard-sidebar"
    assert_includes response.body, "data-dashboard-frame"
    assert_includes response.body, "data-dashboard-topbar"
    assert_includes response.body, "data-dashboard-main"
    assert_equal 1, response.body.scan("data-dashboard-sidebar").count
    assert_includes response.body, "Pagine con controller"
  end

  private

    def create_user(email, **attributes)
      demo_val = attributes.delete(:demo_access)
      user = User.create!(
        {
          email_address: email,
          password: "password123",
          password_confirmation: "password123"
        }.merge(attributes)
      )
      user.create_profile!(display_name: email.split("@").first.capitalize)
      RoleAssignment.create!(profile: user.profile, role: :demo) if demo_val
      user
    end

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
