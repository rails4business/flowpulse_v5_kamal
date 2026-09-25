require "test_helper"

class Flowpulse::DevelopmentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superadmin = User.create!(
      email_address: "flowpulse-development@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    @superadmin.create_profile!(display_name: "Development Admin")
  end

  test "requires authentication" do
    get flowpulse_development_url

    assert_redirected_to new_session_url(return_to: flowpulse_development_path)
  end

  test "superadmin sees grouped implementation sheets and filters" do
    sign_in_superadmin

    get flowpulse_development_url

    assert_response :success
    assert_select "h1", "Sviluppo"
    assert_select "h2", "Flowpulse"
    assert_select "a[href='https://github.com/rails4business/flowpulse_v5_kamal'][target='_blank']", text: /Repository Flowpulse/
    assert_select "a[href='#{flowpulse_development_entry_path("registro-sviluppo-centralizzato")}']"

    get flowpulse_development_url(brand: "impegno")
    assert_response :success
    assert_select "a[href='#{flowpulse_development_entry_path("registro-sviluppo-centralizzato")}']", count: 0
  end

  test "superadmin reads the Markdown detail" do
    sign_in_superadmin

    get flowpulse_development_entry_url("registro-sviluppo-centralizzato")

    assert_response :success
    assert_select "h1", "Registro di sviluppo centralizzato"
    assert_select ".editorial-rich-text h2", text: "Problema"
    assert_select "a[href='#{brand_changelog_entry_path("flowpulse", "registro-sviluppo-centralizzato")}']", text: /Apri il changelog/
    assert_select "p", text: /config\/data\/brands\/flowpulse\/development/
  end

  private

    def sign_in_superadmin
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
    end
end
