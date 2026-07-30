require "test_helper"

module Brands
  class SvuotamenteControllerTest < ActionDispatch::IntegrationTest
    test "renders the standalone webapp prototype" do
      get svuotamente_url

      assert_response :success
      assert_includes response.body, "SvuotaMente"
      assert_select "meta[name='description']"
      assert_select "link[rel='icon'][href^='data:image/svg+xml']"
    end

    test "redirects the old standalone path" do
      get legacy_svuotamente_url

      assert_redirected_to "/brands/svuotamente"
    end
  end
end
