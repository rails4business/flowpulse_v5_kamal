require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "lists canonical public URLs and published articles" do
    get "/sitemap.xml", headers: { "HOST" => "posturacorretta.org" }

    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_includes response.body, "https://posturacorretta.org/posturacorretta/contenuti"
    assert_includes response.body, "consapevolezza-e-coscienza-corporea"
    assert_not_includes response.body, "?ambito="
  end
end
