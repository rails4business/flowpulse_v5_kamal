require "test_helper"

class LlmsControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = User.create!(email_address: "llms-owner@example.com", password: "password123")
    profile = user.create_profile!(display_name: "LLMs Owner")
    owner = RoleAssignment.create!(profile:, role: :ideatore)
    @root = Node.create!(title: "Example Brand", slug: "example-brand", role_assignment: owner, status: "published", visibility: "public")
    @public_child = Node.create!(title: "Public Project", slug: "public-project", parent: @root, status: "published", visibility: "public")
    @private_child = Node.create!(title: "Secret Project", slug: "secret-project", parent: @root, status: "draft", visibility: "private")
    @domain = Domain.create!(hostname: "llms.example", node: @root, locale: "it", site_title: "LLMs Example", site_description: "Descrizione pubblica")
  end

  test "renders a domain-aware public discovery document" do
    get "/llms.txt", headers: { "HOST" => "llms.example" }

    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
    assert_includes response.body, "# LLMs Example"
    assert_includes response.body, "> Descrizione pubblica"
    assert_includes response.body, "https://llms.example/api/v1/domain"
    assert_includes response.body, "Public Project"
    assert_not_includes response.body, "Secret Project"
    assert response.headers["ETag"].present?
  end

  test "uses the optional summary and instructions stored on the domain" do
    @domain.update!(llms_summary: "Sintesi dedicata", llms_instructions: "Considera soltanto le informazioni pubbliche.")

    get "/llms.txt", headers: { "HOST" => "llms.example" }

    assert_response :success
    assert_includes response.body, "> Sintesi dedicata"
    assert_includes response.body, "## Indicazioni"
    assert_includes response.body, "Considera soltanto le informazioni pubbliche."
  end

  test "returns not found when llms discovery is disabled" do
    @domain.update!(llms_enabled: false)

    get "/llms.txt", headers: { "HOST" => "llms.example" }

    assert_response :not_found
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "does not expose a private root node" do
    @root.update!(status: "draft", visibility: "private")

    get "/llms.txt", headers: { "HOST" => "llms.example" }

    assert_response :not_found
    assert_not_includes response.body, "Secret Project"
  end

  test "redirects an alias to the canonical llms document" do
    Domain.create!(hostname: "www.llms.example", canonical_host: "llms.example", locale: "it")

    get "/llms.txt", headers: { "HOST" => "www.llms.example" }

    assert_response :moved_permanently
    assert_redirected_to "https://llms.example/llms.txt"
  end
end
