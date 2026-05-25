require "test_helper"

class DomainsControllerTest < ActionDispatch::IntegrationTest
  test "renders fallback home for unconfigured host" do
    get root_url

    assert_response :success
    assert_includes response.body, "Flowpulse"
  end

  test "renders configured domain target" do
    Domain.create!(hostname: "posturacorretta.org", target_controller: "pages", target_action: "posturacorretta", locale: "it")
    host! "posturacorretta.org"

    get root_url

    assert_response :success
    assert_includes response.body, "PosturaCorretta"
  end

  test "renders configured controller target" do
    Domain.create!(hostname: "custom.org", target_controller: "pages", target_action: "flowpulse", locale: "it")
    host! "custom.org"

    get root_url

    assert_response :success
    assert_includes response.body, "Flowpulse"
  end

  test "redirects canonical domain aliases" do
    Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      locale: "it"
    )
    host! "www.posturacorretta.org"

    get root_url

    assert_redirected_to "http://posturacorretta.org/"
  end
end
