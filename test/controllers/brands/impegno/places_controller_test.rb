require "test_helper"

module Brands
  module Impegno
    class PlacesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "places@example.com", password: "password123", password_confirmation: "password123")
        @user.create_profile!(display_name: "Places User", username: "places_user")
        post session_url, params: { email_address: @user.email_address, password: "password123" }
      end

      test "lists and creates places for the current profile" do
        get impegno_places_url(workspace: "1")

        assert_response :success
        assert_select "turbo-frame#impegno_workspace"
        assert_select "h1", text: "Luoghi"

        post impegno_places_url, params: { impegno_place: { name: "Studio Calvisano", kind: "studio", address: "Via Roma 1, Calvisano", online_url: "https://example.test/studio" } }

        assert_redirected_to impegno_path(area: "places")
        place = @user.profile.impegno_places.find_by!(name: "Studio Calvisano")
        assert_equal "studio", place.kind
      end
    end
  end
end
