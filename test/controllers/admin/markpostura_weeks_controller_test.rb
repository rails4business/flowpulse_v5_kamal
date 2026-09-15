require "test_helper"

module Admin
  class MarkposturaWeeksControllerTest < ActionDispatch::IntegrationTest
    setup do
      @superadmin = User.create!(
        email_address: "weekplan-superadmin@example.com",
        password: "password123",
        password_confirmation: "password123",
        superadmin: true,
        active_role: :superadmin
      )
    end

    test "anonymous visitor cannot read the weekly YAML" do
      get admin_markpostura_week_url("2026-W38")

      assert_redirected_to new_session_path(return_to: admin_markpostura_week_path("2026-W38"))
    end

    test "superadmin can read the weekly YAML and its path" do
      post session_url, params: { email_address: @superadmin.email_address, password: "password123" }

      get admin_markpostura_week_url("2026-W38")

      assert_response :success
      assert_select "h1", text: "Week Plan 2026-W38"
      assert_includes response.body, "config/data/markpostura/settimane/2026-W38.yml"
      assert_includes response.body, "Gruppo PosturaCorretta"
    end
  end
end
