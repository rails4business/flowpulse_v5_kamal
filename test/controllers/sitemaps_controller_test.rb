require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = User.create!(email_address: "sitemap-owner@example.com", password: "password123")
    profile = user.create_profile!(display_name: "Sitemap Owner")
    @owner = RoleAssignment.create!(profile: profile, role: :ideatore)
  end

  test "lists canonical public URLs and published articles" do
    node = Node.create!(title: "PosturaCorretta", slug: "posturacorretta", role_assignment: @owner, status: "published", visibility: "public")
    Domain.create!(hostname: "posturacorretta.org", node: node, locale: "it")

    get "/sitemap.xml", headers: { "HOST" => "posturacorretta.org" }

    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_includes response.body, "https://posturacorretta.org/posturacorretta/contenuti"
    assert_includes response.body, "consapevolezza-e-coscienza-corporea"
    assert_not_includes response.body, "?ambito="
  end

  test "keeps each sitemap inside its canonical domain" do
    node = Node.create!(title: "Flowpulse", slug: "flowpulse", role_assignment: @owner, status: "published", visibility: "public")
    Domain.create!(hostname: "flowpulse.net", node: node, locale: "it")

    get "/sitemap.xml", headers: { "HOST" => "flowpulse.net" }

    assert_response :success
    assert_not_includes response.body, "https://flowpulse.net/flowpulse/rete"
    assert_not_includes response.body, "posturacorretta.org"
    assert_not_includes response.body, "/posturacorretta/"
  end

  test "does not expose a sitemap for a domain whose root Node is not public" do
    node = Node.create!(title: "Private Brand", role_assignment: @owner, status: "draft", visibility: "private")
    Domain.create!(hostname: "private.example", node: node, locale: "it")

    get "/sitemap.xml", headers: { "HOST" => "private.example" }

    assert_response :not_found
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_empty response.body
  end

  test "a future public domain receives at least its root URL without catalog configuration" do
    node = Node.create!(title: "Future Brand", role_assignment: @owner, status: "published", visibility: "public")
    Domain.create!(hostname: "future-public.example", node:, locale: "it")

    get "/sitemap.xml", headers: { "HOST" => "future-public.example" }

    assert_response :success
    assert_includes response.body, "https://future-public.example/"
  end
end
