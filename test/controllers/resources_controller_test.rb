require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = User.create!(
      email_address: "resources-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true
    )

    post session_url, params: { email_address: user.email_address, password: "password123" }
  end

  test "assigned admin can get resources index" do
    delete session_url
    user = User.create!(
      email_address: "assigned-admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.role_assignments.create!(role: :admin)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get admin_risorse_index_url

    assert_response :success
    assert_includes response.body, "Materiali, transazioni, contatti, abilita ed energia"
  end

  test "non admin cannot get resources index" do
    delete session_url
    user = User.create!(
      email_address: "not-admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get admin_risorse_index_url

    assert_redirected_to root_url
  end

  test "admin in demo mode cannot get resources index" do
    delete session_url
    user = User.create!(
      email_address: "demo-mode-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      demo_access: true,
      active_role: :demo
    )
    user.role_assignments.create!(role: :admin)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get admin_risorse_index_url

    assert_redirected_to root_url
  end

  test "should get resources index with tabs" do
    get admin_risorse_index_url
    assert_response :success
    assert_includes response.body, "Materiali, transazioni, contatti, abilita ed energia"
    assert_includes response.body, "Eventi"
    assert_includes response.body, "Transazioni"
    assert_includes response.body, "Attenzione"
    assert_includes response.body, "Dashboard Admin"
    assert_not_includes response.body, "Esperienze, categorie e brand"
    assert_not_includes response.body, "Prototipi e viste sandbox"
  end

  test "should switch to abilita tab" do
    get admin_risorse_index_url(tab: "abilita")
    assert_response :success
    assert_includes response.body, "Valutazione mobilita articolare"
  end

  test "should get resource detail" do
    get admin_risorse_url(10)
    assert_response :success
    assert_includes response.body, "Riparto evento Postura in Vetta"
    assert_includes response.body, "Torna a risorse"
  end
end
