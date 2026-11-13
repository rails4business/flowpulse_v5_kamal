require "test_helper"

module Admin
  class MetroMapsControllerTest < ActionDispatch::IntegrationTest
    setup do
      owner = User.create!(
        email_address: "metro-owner@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      profile = owner.create_profile!(display_name: "Metro Owner", username: "metro_owner")
      @role = RoleAssignment.create!(profile: profile, role: :ideatore)
      @root = Node.create!(role_assignment: @role, title: "Metro Brand", slug: "metro-brand", status: "published")
      @child = Node.create!(role_assignment: @role, parent: @root, title: "Prima stazione", slug: "prima-stazione", status: "published")
      @second_child = Node.create!(role_assignment: @role, parent: @child, title: "Seconda stazione", slug: "seconda-stazione", status: "published")
      @external = Node.create!(role_assignment: @role, title: "Stazione esterna", slug: "stazione-esterna", status: "published")
      @domain = Domain.create!(hostname: "metro-brand.test", node: @root, role_assignment: @role, active: true, primary: true)
      Domain.create!(hostname: "external-brand.test", node: @external, role_assignment: @role, active: true, primary: true)
      Node.create!(
        role_assignment: @role,
        parent: @child,
        link_node: @external,
        title: "Ponte esterno",
        slug: "ponte-esterno",
        view_type: "access_bridge",
        status: "published"
      )
    end

    test "requires authentication" do
      get flowpulse_metro_map_url(hostname: @domain.hostname)

      assert_redirected_to new_session_url(return_to: flowpulse_metro_map_path(hostname: @domain.hostname))
    end

    test "non superadmin cannot open the metro map" do
      user = User.create!(email_address: "metro-user@example.com", password: "password123", password_confirmation: "password123")
      sign_in(user)

      get flowpulse_metro_map_url(hostname: @domain.hostname)

      assert_redirected_to viaggiatori_url
    end

    test "superadmin sees domain stations hierarchy and external bridge" do
      superadmin = create_superadmin
      sign_in(superadmin)

      get flowpulse_metro_map_url(hostname: @domain.hostname)

      assert_response :success
      assert_select "[data-controller='metro-map']", count: 1
      assert_select "h1", text: @domain.hostname
      assert_includes response.body, @root.title
      assert_includes response.body, @child.title
      assert_includes response.body, @external.title
      assert_includes response.body, "&quot;kind&quot;:&quot;hierarchy&quot;"
      assert_includes response.body, "&quot;kind&quot;:&quot;bridge&quot;"
      assert_includes response.body, "&quot;terminal&quot;:true"
      assert_includes response.body, "&quot;destinationDomain&quot;:&quot;external-brand.test&quot;"
      assert_includes response.body, flowpulse_metro_map_path(hostname: "external-brand.test")
      assert_not_includes response.body, "Ponte esterno"
    end

    test "superadmin sees lines with ordered stations and their offers" do
      sign_in(create_superadmin)
      line = MetroLine.create!(
        domain: @domain, slug: "linea-mappa", title: "Linea mappa",
        start_node: @root, end_node: @second_child,
        station_node_ids: [@root.id, @child.id, @second_child.id],
        settings: { "color" => "#E11D48" }
      )
      [@root, @child, @second_child].each { |node| node.update!(line_slugs: [line.slug]) }
      Offer.create!(metro_line: line, slug: "avvio", title: "Avvio", start_node: @root, end_node: @root)
      Offer.create!(metro_line: line, slug: "completa", title: "Completa", start_node: @root, end_node: @second_child,
        included_offer_slugs: ["avvio"], previous_purchase_mode: "credit")

      get flowpulse_metro_map_url(hostname: @domain.hostname)

      graph = JSON.parse(css_select("[data-controller='metro-map']").first["data-metro-map-graph-value"])
      line_graph = graph.fetch("lines").sole
      assert_equal "#E11D48", line_graph["color"]
      assert_equal [@root, @child, @second_child].map { |node| "node-#{node.id}" }, line_graph["stationIds"]
      assert_equal [["avvio", 0, 0, []], ["completa", 0, 2, ["Avvio"]]],
        line_graph["offers"].map { |offer| offer.values_at("slug", "startIndex", "endIndex", "includes") }
    end

    test "rejects an offer that includes a longer offer" do
      sign_in(create_superadmin)
      line = MetroLine.create!(
        domain: @domain, slug: "linea-inclusa", title: "Linea inclusa",
        start_node: @root, end_node: @second_child,
        station_node_ids: [@root.id, @child.id, @second_child.id]
      )
      [@root, @child, @second_child].each { |node| node.update!(line_slugs: [line.slug]) }
      Offer.create!(metro_line: line, slug: "intera", title: "Intera", start_node: @root, end_node: @second_child)

      post flowpulse_metro_map_offers_url(hostname: @domain.hostname), params: {
        title: "Breve", slug: "breve", metro_line_id: line.id,
        start_node_id: @root.id, end_node_id: @child.id,
        included_offer_slugs: ["intera"], previous_purchase_mode: "credit"
      }

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      assert_equal "L'offerta inclusa Intera esce dalla tratta", flash[:alert]
      assert_not Offer.exists?(slug: "breve")
    end

    test "superadmin saves station positions only for the selected domain map" do
      sign_in(create_superadmin)

      patch flowpulse_metro_map_positions_url(hostname: @domain.hostname), params: {
        positions: [{ node_id: @child.id, x: 420.5, y: 180.25, collapsed: true }]
      }, as: :json

      assert_response :success
      map = MetroMap.find_by!(domain: @domain)
      placement = map.placements.find_by!(node: @child)
      assert_equal 420.5, placement.x
      assert_equal 180.25, placement.y
      assert placement.collapsed?
    end

    test "superadmin creates an explicitly ordered metro line and updates station memberships" do
      sign_in(create_superadmin)

      post flowpulse_metro_map_lines_url(hostname: @domain.hostname), params: {
        title: "Linea prova",
        slug: "linea-prova",
        station_node_ids: [@root.id, @child.id, @second_child.id].join(",")
      }

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      line = MetroLine.find_by!(slug: "linea-prova")
      assert_equal [@root.id, @child.id, @second_child.id], line.station_node_ids
      assert_equal %w[metro-brand prima-stazione seconda-stazione], line.ordered_nodes.map(&:slug)
      assert @root.reload.line_slugs.include?(line.slug)
      assert @second_child.reload.line_slugs.include?(line.slug)
    end

    test "superadmin creates an offer on a selected line segment" do
      sign_in(create_superadmin)
      line = MetroLine.create!(
        domain: @domain, slug: "linea-offerte", title: "Linea offerte",
        start_node: @root, end_node: @second_child,
        station_node_ids: [@root.id, @child.id, @second_child.id]
      )
      [@root, @child, @second_child].each { |node| node.update!(line_slugs: [line.slug]) }

      post flowpulse_metro_map_offers_url(hostname: @domain.hostname), params: {
        title: "Pacchetto iniziale", slug: "pacchetto-iniziale", metro_line_id: line.id,
        start_node_id: @child.id, end_node_id: @second_child.id,
        previous_purchase_mode: "discount", discount_percent: "15"
      }

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      offer = Offer.find_by!(slug: "pacchetto-iniziale")
      assert_equal @child, offer.start_node
      assert_equal @second_child, offer.end_node
      assert_equal 15, offer.discount_percent
      assert_not @root.reload.offer_slugs.include?(offer.slug)
      assert @child.reload.offer_slugs.include?(offer.slug)
      assert @second_child.reload.offer_slugs.include?(offer.slug)
    end

    test "superadmin downloads domain map and catalog YAML files" do
      sign_in(create_superadmin)
      map = MetroMap.create!(domain: @domain, title: "Mappa test")
      map.placements.create!(node: @child, x: 120, y: 240, collapsed: true)

      get flowpulse_metro_map_export_url(hostname: @domain.hostname, catalog: "map")
      assert_response :success
      assert_includes response.media_type, "yaml"
      assert_includes response.body, @domain.hostname
      assert_includes response.body, "title: Mappa test"
      assert_not_includes response.body, "prima-stazione"

      get flowpulse_metro_map_export_url(hostname: @domain.hostname, catalog: "nodes")
      assert_response :success
      assert_includes response.headers["Content-Disposition"], "nodes.yml"
      assert_equal MetroCatalogExporter.nodes_yaml, response.body
    end

    test "superadmin creates and removes a bridge from the metro editor" do
      sign_in(create_superadmin)

      post flowpulse_metro_map_bridges_url(hostname: @domain.hostname), params: {
        source_node_id: @second_child.id, target_node_id: @external.id
      }

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      bridge = @second_child.children.find_by!(link_node: @external, view_type: "access_bridge")

      delete flowpulse_metro_map_bridge_url(hostname: @domain.hostname, id: bridge.id)

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      assert_not Node.exists?(bridge.id)
    end

    test "superadmin changes parent without allowing hierarchy cycles" do
      sign_in(create_superadmin)
      sibling = Node.create!(role_assignment: @role, parent: @root, title: "Nuovo genitore", slug: "nuovo-genitore", status: "published")

      patch flowpulse_metro_map_parent_url(hostname: @domain.hostname), params: {
        node_id: @second_child.id, parent_node_id: sibling.id
      }

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      assert_equal sibling, @second_child.reload.parent

      patch flowpulse_metro_map_parent_url(hostname: @domain.hostname), params: {
        node_id: sibling.id, parent_node_id: @second_child.id
      }

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      assert_equal @root, sibling.reload.parent
    end

    test "superadmin adds a node under a station from the metro editor" do
      sign_in(create_superadmin)

      post flowpulse_metro_map_nodes_url(hostname: @domain.hostname), params: {
        parent_node_id: @child.id,
        title: "Nuovo servizio",
        description: "Creato dalla mappa",
        map_color: "#2563EB"
      }

      assert_redirected_to flowpulse_metro_map_path(hostname: @domain.hostname)
      node = Node.find_by!(slug: "nuovo-servizio")
      assert_equal @child, node.parent
      assert_equal "Creato dalla mappa", node.description
      assert_equal "#2563EB", node.map_color
    end

    private

      def sign_in(user)
        post session_url, params: { email_address: user.email_address, password: "password123" }
      end

      def create_superadmin
        User.create!(
          email_address: "metro-superadmin-#{SecureRandom.hex(4)}@example.com",
          password: "password123",
          password_confirmation: "password123",
          superadmin: true,
          active_role: :superadmin
        )
      end
  end
end
