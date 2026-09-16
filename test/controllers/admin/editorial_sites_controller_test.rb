require "test_helper"

module Admin
  class EditorialSitesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @superadmin = User.create!(
        email_address: "editorial-sites-superadmin@example.com",
        password: "password123",
        password_confirmation: "password123",
        superadmin: true,
        active_role: :superadmin
      )
    end

    test "anonymous visitor cannot preview an editorial Site" do
      get admin_editorial_site_url("markpostura_it")

      assert_redirected_to new_session_path(return_to: admin_editorial_site_path("markpostura_it"))
    end

    test "superadmin can preview the MarkPostura home" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }

      get admin_editorial_site_url("markpostura_it")

      assert_response :success
      assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
      assert_select "h1", count: 1
      assert_select "h1", text: "Tre progetti, una visione."
      assert_select "#progetti article, #progetti a", count: 3
      assert_select "#ingresso li", count: 4
      assert_includes response.body, "Una sola webapp per sostenere i progetti."
    end

    test "unknown Site returns not found" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }

      get admin_editorial_site_url("missing_site")

      assert_response :not_found
    end
  end
end
