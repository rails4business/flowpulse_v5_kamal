require "test_helper"

class DedicatedDomainsControllerTest < ActionDispatch::IntegrationTest
  test "renders fallback home for unconfigured host" do
    get root_url

    assert_response :success
    assert_includes response.body, "Flowpulse"
  end

  test "renders metro app for configured posture domain" do
    host! "posturacorretta.it"

    get root_url

    assert_response :success
    assert_includes response.body, "markpostura-gallery-page"
  end

  test "redirects canonical domain aliases" do
    host! "www.posturacorretta.it"

    get root_url

    assert_redirected_to "http://posturacorretta.it/"
  end
end
