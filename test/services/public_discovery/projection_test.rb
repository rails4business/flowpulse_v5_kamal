require "test_helper"

module PublicDiscovery
  class ProjectionTest < ActiveSupport::TestCase
    setup do
      user = User.create!(email_address: "projection-owner@example.com", password: "password123")
      @profile = user.create_profile!(display_name: "Projection Owner")
      @owner = RoleAssignment.create!(profile: @profile, role: :ideatore)
      @root = Node.create!(
        title: "Public Brand",
        slug: "public-brand",
        role_assignment: @owner,
        status: "published",
        visibility: "public"
      )
      @domain = Domain.create!(
        hostname: "public.example",
        node: @root,
        locale: "it",
        site_title: "Public Example",
        site_description: "Public description"
      )
    end

    test "projects public nodes and stops at private branches and sub-brand boundaries" do
      public_child = Node.create!(title: "Public Child", parent: @root, status: "published", visibility: "public")
      private_child = Node.create!(title: "Private Child", parent: @root, status: "draft", visibility: "private")
      hidden_descendant = Node.create!(title: "Hidden Descendant", parent: private_child, status: "published", visibility: "public")
      boundary = Node.create!(title: "Sub Brand", parent: @root, status: "published", visibility: "public")
      hidden_boundary_child = Node.create!(title: "Other Site Child", parent: boundary, status: "published", visibility: "public")
      Domain.create!(hostname: "sub.example", node: boundary, locale: "it")

      projection = Projection.new(@domain).call
      nodes = projection.fetch("nodes")

      assert_equal "https://public.example/", projection.dig("domain", "url")
      assert_equal "root", projection.dig("root_node", "relation")
      assert_includes nodes.map { |node| node["id"] }, public_child.id
      assert_not_includes nodes.map { |node| node["id"] }, private_child.id
      assert_not_includes nodes.map { |node| node["id"] }, hidden_descendant.id
      assert_not_includes nodes.map { |node| node["id"] }, hidden_boundary_child.id
      boundary_payload = nodes.find { |node| node["id"] == boundary.id }
      assert_equal "sub_brand", boundary_payload.fetch("relation")
      assert_equal true, boundary_payload.fetch("boundary")
      assert_equal "https://sub.example/", boundary_payload.fetch("url")
    end

    test "represents a bridge as a relation without duplicating its target" do
      target = Node.create!(title: "Bridge Target", role_assignment: @owner, status: "published", visibility: "public")
      bridge = Node.create!(title: "Bridge", parent: @root, link_node: target, status: "published", visibility: "public")

      nodes = Projection.new(@domain).call.fetch("nodes")
      bridge_payload = nodes.find { |node| node["id"] == bridge.id }

      assert_equal "bridge", bridge_payload.fetch("relation")
      assert_equal target.id, bridge_payload.dig("target", "id")
      assert_equal "https://public.example/nodes/#{target.id}", bridge_payload.dig("target", "url")
      assert_not_includes nodes.map { |node| node["id"] }, target.id
    end

    test "does not project a private root or a canonical alias" do
      @root.update!(status: "draft", visibility: "private")
      assert_nil Projection.new(@domain).call

      @root.update!(status: "published", visibility: "public")
      alias_domain = Domain.create!(hostname: "www.public.example", canonical_host: "public.example", locale: "it")
      assert_nil Projection.new(alias_domain).call
    end

    test "projects only public products from active and available skills" do
      skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents", status: "available")
      activation = skill.reusable_skill_nodes.create!(node: @root, activated_by_profile: @profile, status: "active")
      public_product = activation.skill_products.create!(title: "Guida pubblica", status: "published", visibility: "public", body: "# Guida", created_by_profile: @profile)
      activation.skill_products.create!(title: "Guida privata", status: "published", visibility: "private", body: "Segreto", created_by_profile: @profile)

      resources = Projection.new(@domain).call.fetch("resources")

      assert_equal [public_product.id], resources.map { |resource| resource.fetch("id") }
      assert_equal "https://public.example/resources/#{public_product.id}/guida-pubblica", resources.first.fetch("url")
    end
  end
end
