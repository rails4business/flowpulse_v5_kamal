require "test_helper"

module Admin
  class PrototypePagesControllerTest < ActionDispatch::IntegrationTest
    test "only a superadmin can open a private prototype" do
      get admin_prototype_path(path: "viste_html/6_weekplan.html")
      assert_redirected_to new_session_path(return_to: "/admin/prototipi/viste_html/6_weekplan.html")

      superadmin = User.create!(
        email_address: "prototype-superadmin@example.com",
        password: "password123",
        password_confirmation: "password123",
        superadmin: true,
        active_role: :superadmin
      )
      post session_url, params: { email_address: superadmin.email_address, password: "password123" }

      get admin_prototype_path(path: "viste_html/6_weekplan.html")
      assert_response :success
      assert_equal "text/html", response.content_type

      get admin_prototype_path(path: "viste_html/home_posturacorretta_programma.html")
      assert_response :success
    assert_select "h1", text: "Programma lezioni"
      assert_select "ol[aria-label='Lezioni del programma studenti'] li", count: 43
    end
  end
end
