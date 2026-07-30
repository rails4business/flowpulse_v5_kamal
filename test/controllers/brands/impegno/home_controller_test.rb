require "test_helper"

module Brands
  module Impegno
    class HomeControllerTest < ActionDispatch::IntegrationTest
      test "renders the public Impegno brand page" do
        get impegno_url

        assert_response :success
        assert_select "h1", /Il tuo tempo/
        assert_select "a[href=?]", new_user_path(return_to: data_commitments_path), text: /Apri Impegno/
      end
    end
  end
end
