require "test_helper"

module Brands
  module Impegno
    class ComposerControllerTest < ActionDispatch::IntegrationTest
      test "keeps the operational composer private" do
        get impegno_composer_path
        assert_redirected_to new_session_path(return_to: impegno_composer_path)

        superadmin = User.create!(email_address: "composer-superadmin@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
        superadmin.create_profile!(display_name: "Composer", username: "composer")
        post session_path, params: { email_address: superadmin.email_address, password: "password123" }

        get impegno_composer_path
        assert_response :success
        assert_select "h1", text: "Root, Day, Sessione, Task"
        assert_select "button", text: "+ Root"
      end
    end
  end
end
