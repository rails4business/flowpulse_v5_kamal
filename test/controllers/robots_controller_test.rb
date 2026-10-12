require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = User.create!(email_address: "robots-owner@example.com", password: "password123")
    profile = user.create_profile!(display_name: "Robots Owner")
    @owner = RoleAssignment.create!(profile: profile, role: :ideatore)
  end

  test "returns domain-aware rules and sitemap" do
    node = Node.create!(title: "Flowpulse", role_assignment: @owner, status: "published", visibility: "public")
    Domain.create!(hostname: "flowpulse.net", node: node, locale: "it")

    get "/robots.txt", headers: { "HOST" => "flowpulse.net" }

    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
    assert_includes response.body, "Disallow: /admin"
    assert_includes response.body, "Sitemap: https://flowpulse.net/sitemap.xml"
    assert_includes response.body, "# Public AI discovery: https://flowpulse.net/llms.txt"
    assert_not_includes response.body, "posturacorretta.org"
  end

  test "blocks crawling for a private domain" do
    node = Node.create!(title: "Private", role_assignment: @owner, status: "draft", visibility: "private")
    Domain.create!(hostname: "private.example", node: node, locale: "it")

    get "/robots.txt", headers: { "HOST" => "private.example" }

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_equal "User-agent: *\nDisallow: /\n", response.body
  end
end
