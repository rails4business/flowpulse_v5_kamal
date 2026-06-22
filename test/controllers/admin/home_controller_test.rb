require "test_helper"

module Admin
  class HomeControllerTest < ActionDispatch::IntegrationTest
    setup do
      @superadmin = User.create!(
        email_address: "home-superadmin@example.com",
        password: "password123",
        password_confirmation: "password123",
        superadmin: true,
        active_role: :superadmin
      )

      @traveler = User.create!(
        email_address: "home-traveler@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      @traveler.create_profile!(display_name: "Traveler User")

      @domain = Domain.create!(
        hostname: "example.com",
        locale: "it",
        target_controller: "landing",
        target_action: "posturacorretta",
        active: true
      )
    end

    test "superadmin can see dashboard with statistics" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get admin_dashboard_url

      assert_response :success
      assert_select "h1", "Superadmin Dashboard"
      assert_select ".superadmin-tabs"
      assert_includes response.body, "Panoramica &amp; Diagnostica"
      assert_includes response.body, "Creator"
      assert_includes response.body, "Domini"
    end

    test "superadmin can see dashboard worlds tab" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get admin_dashboard_path(tab: "worlds")
      assert_response :success
      assert_select "h2", "Elenco Creator"
    end

    test "superadmin can see dashboard domains tab" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get admin_dashboard_path(tab: "domains")
      assert_response :success
      assert_select "h2", "Domini Associati ai Creator"
    end

    test "superadmin can see dashboard guide tab" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get admin_dashboard_path(tab: "guide")
      assert_response :success
      assert_select "h2", "Pagine per Ruolo"
    end

    test "traveler cannot see dashboard" do
      post session_url, params: { email_address: @traveler.email_address, password: "password123" }
      get admin_dashboard_url

      assert_redirected_to viaggiatori_url
    end

    test "superadmin with traveler active role cannot see dashboard" do
      @superadmin.update!(active_role: :traveler)

      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
      get admin_dashboard_url

      assert_redirected_to viaggiatori_url
    end

    test "anonymous user cannot see dashboard" do
      get admin_dashboard_url
      assert_redirected_to new_session_url
    end

    test "superadmin can set and reset domain override on localhost" do
      # Simulation: request to localhost
      host! "localhost"

      post session_path, params: { email_address: @superadmin.email_address, password: "password123" }

      post admin_set_override_path, params: { domain_id: @domain.id }
      assert_redirected_to admin_dashboard_path
      follow_redirect!

      assert_includes response.body, "Simulazione attiva: <strong>example.com</strong>"

      # Reset simulation
      post admin_set_override_path, params: { domain_id: nil }
      assert_redirected_to admin_dashboard_path
      follow_redirect!

      assert_includes response.body, "Nessuno (Standalone Fallback)"
    end

    test "domain simulation override is ignored in production (non-localhost)" do
      # Set host to non-local (production scenario)
      host! "other-host.net"

      post session_path, params: { email_address: @superadmin.email_address, password: "password123" }

      # Set override
      post admin_set_override_path, params: { domain_id: @domain.id }
      assert_redirected_to admin_dashboard_path
      follow_redirect!

      assert_response :success
      assert_includes response.body, "other-host.net"
      assert_not_includes response.body, "Simulazione attiva"
    end
  end
end
