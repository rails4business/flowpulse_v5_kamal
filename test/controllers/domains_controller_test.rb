require "test_helper"

class DomainsControllerTest < ActionDispatch::IntegrationTest
  test "renders fallback home for unconfigured host" do
    get root_url

    assert_response :success
    assert_includes response.body, "Flowpulse"
  end

  test "renders configured domain action" do
    Domain.create!(hostname: "posturacorretta.org", action: "markpostura", locale: "it")
    host! "posturacorretta.org"

    get root_url

    assert_response :success
    assert_includes response.body, "markpostura-gallery-page"
  end

  test "renders html home when present" do
    Domain.create!(hostname: "custom.org", action: "mvp_home", locale: "it", html_home: "<section>Custom home</section>")
    host! "custom.org"

    get root_url

    assert_response :success
    assert_includes response.body, "Custom home"
  end

  test "redirects canonical domain aliases" do
    Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      action: "mvp_home",
      locale: "it"
    )
    host! "www.posturacorretta.org"

    get root_url

    assert_redirected_to "http://posturacorretta.org/"
  end
end
