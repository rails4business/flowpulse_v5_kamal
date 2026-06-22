require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = User.create!(
      email_address: "resources-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )

    post session_url, params: { email_address: user.email_address, password: "password123" }
  end

  test "assigned admin can get resources index" do
    delete session_url
    user = User.create!(
      email_address: "assigned-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :admin
    )
    user.create_profile!(display_name: "Assigned Admin")
    RoleAssignment.create!(profile: user.profile, role: :admin, parent: create_creator_assignment)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get admin_risorse_index_url

    assert_response :success
    assert_includes response.body, "Materiali, transazioni, contatti, abilita ed energia"
  end

  test "assigned admin with traveler active role cannot get resources index" do
    delete session_url
    user = User.create!(
      email_address: "assigned-admin-traveler-active@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    user.create_profile!(display_name: "Assigned Admin Traveler Active")
    RoleAssignment.create!(profile: user.profile, role: :admin, parent: create_creator_assignment)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get admin_risorse_index_url

    assert_redirected_to viaggiatori_url
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

    assert_redirected_to viaggiatori_url
  end

  test "admin in demo mode cannot get resources index" do
    delete session_url
    user = User.create!(
      email_address: "demo-mode-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :demo
    )
    user.create_profile!(display_name: "Demo Admin")
    RoleAssignment.create!(profile: user.profile, role: :demo)
    RoleAssignment.create!(profile: user.profile, role: :admin, parent: create_creator_assignment)

    post session_url, params: { email_address: user.email_address, password: "password123" }
    get admin_risorse_index_url

    assert_redirected_to demo_viaggiatori_url
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

  private

    def create_creator_assignment
      creator = User.create!(
        email_address: "resources-creator-#{SecureRandom.hex(4)}@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      creator.create_profile!(display_name: "Creator User")
      RoleAssignment.create!(profile: creator.profile, role: :creator_of_worlds)
    end
end
