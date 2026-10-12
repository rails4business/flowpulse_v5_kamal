require "test_helper"

module Api
  module V1
    class PublicDiscoveryTest < ActionDispatch::IntegrationTest
      setup do
        user = User.create!(email_address: "public-api-owner@example.com", password: "password123")
        @profile = user.create_profile!(display_name: "Public API Owner")
        owner = RoleAssignment.create!(profile: @profile, role: :ideatore)
        @root = Node.create!(
          title: "API Brand",
          slug: "api-brand",
          role_assignment: owner,
          status: "published",
          visibility: "public"
        )
        @child = Node.create!(
          title: "Public Child",
          slug: "public-child",
          parent: @root,
          status: "published",
          visibility: "public"
        )
        @private_child = Node.create!(
          title: "Private Child",
          slug: "private-child",
          parent: @root,
          status: "draft",
          visibility: "private"
        )
        @domain = Domain.create!(
          hostname: "api.example",
          node: @root,
          locale: "it",
          site_title: "API Example",
          site_description: "Public API example"
        )
        host! "api.example"
      end

      test "returns the public domain envelope" do
        get api_v1_domain_url

        assert_response :success
        payload = response.parsed_body
        assert_equal PublicDiscovery::Projection::SCHEMA_VERSION, payload.fetch("schema_version")
        assert_equal "api.example", payload.dig("domain", "hostname")
        assert_equal "api-brand", payload.dig("root_node", "slug")
        assert_equal 2, payload.fetch("node_count")
        assert_equal "https://api.example/api/v1/nodes", payload.dig("links", "nodes")
        assert_equal "*", response.headers["Access-Control-Allow-Origin"]
        assert_includes response.headers.fetch("Cache-Control"), "public"
        assert response.headers["ETag"].present?
      end

      test "supports conditional requests with ETag" do
        get api_v1_nodes_url
        etag = response.headers.fetch("ETag")

        get api_v1_nodes_url, headers: { "If-None-Match" => etag }

        assert_response :not_modified
        assert_empty response.body
      end

      test "lists only nodes allowed by the public projection" do
        get api_v1_nodes_url

        assert_response :success
        payload = response.parsed_body
        assert_equal 2, payload.fetch("count")
        assert_equal %w[api-brand public-child], payload.fetch("nodes").map { |node| node.fetch("slug") }
        assert_not_includes response.body, "private-child"
      end

      test "shows a public node and its public children" do
        grandchild = Node.create!(
          title: "Grandchild",
          slug: "grandchild",
          parent: @child,
          status: "published",
          visibility: "public"
        )

        get api_v1_node_url(slug: @child.slug)

        assert_response :success
        payload = response.parsed_body
        assert_equal @child.id, payload.dig("node", "id")
        assert_equal [grandchild.id], payload.fetch("children").map { |node| node.fetch("id") }
        assert_equal "https://api.example/api/v1/nodes/public-child", payload.dig("links", "self")
      end

      test "returns a stable 404 for a private or unknown node" do
        get api_v1_node_url(slug: @private_child.slug)

        assert_response :not_found
        assert_equal "node_not_found", response.parsed_body.dig("error", "code")
        assert_equal "no-store", response.headers["Cache-Control"]
      end

      test "does not expose a domain whose root is private" do
        @root.update!(status: "draft", visibility: "private")

        get api_v1_domain_url

        assert_response :not_found
        assert_equal "domain_not_public", response.parsed_body.dig("error", "code")
      end

      test "redirects an alias to the canonical API URL" do
        Domain.create!(hostname: "www.api.example", canonical_host: "api.example", locale: "it")
        host! "www.api.example"

        get api_v1_nodes_url

        assert_response :moved_permanently
        assert_redirected_to "https://api.example/api/v1/nodes"
      end

      test "lists and shows only public products of active skills" do
        skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents", status: "available")
        activation = skill.reusable_skill_nodes.create!(node: @child, activated_by_profile: @profile, status: "active")
        product = activation.skill_products.create!(
          title: "API Resource",
          status: "published",
          visibility: "public",
          body: "# Corpo pubblico",
          data: { "description" => "Descrizione pubblica" },
          created_by_profile: @profile
        )
        activation.skill_products.create!(title: "Private Resource", status: "published", visibility: "private", body: "Segreto", created_by_profile: @profile)

        get api_v1_resources_url
        assert_response :success
        assert_equal [product.id], response.parsed_body.fetch("resources").map { |resource| resource.fetch("id") }
        assert_not_includes response.body, "Private Resource"

        get api_v1_resource_url(product)
        assert_response :success
        assert_equal "# Corpo pubblico", response.parsed_body.dig("resource", "body")
        assert_equal "https://api.example/resources/#{product.id}/api-resource", response.parsed_body.dig("links", "html")
      end
    end
  end
end
