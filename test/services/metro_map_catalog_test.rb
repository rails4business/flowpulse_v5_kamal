require "test_helper"

class MetroMapCatalogTest < ActiveSupport::TestCase
  setup do
    user = User.create!(
      email_address: "map-catalog@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    profile = user.create_profile!(display_name: "Map Catalog", username: "markpostura")
    RoleAssignment.create!(profile:, role: :ideatore)
    NodeCatalog.from_config("test").import!
    root = Node.find_by!(slug: "posturacorretta")
    Domain.create!(
      hostname: "posturacorretta.org",
      node: root,
      role_assignment: root.role_assignment,
      active: true,
      primary: true
    )
  end

  test "imports placements declared on nodes" do
    catalog = MetroMapCatalog.new(
      { "maps" => { "posturacorretta.org" => { "title" => "Mappa PosturaCorretta", "status" => "published" } } },
      nodes_config: {
        "nodes" => {
          "postura-e-fisiologia" => { "map_placements" => { "posturacorretta.org" => { "x" => 120, "y" => 340, "collapsed" => true } } }
        }
      }
    )

    result = catalog.import!
    catalog.import!

    map = MetroMap.find_by!(domain: Domain.find_by!(hostname: "posturacorretta.org"))
    placement = map.placements.find_by!(node: Node.find_by!(slug: "postura-e-fisiologia"))
    assert_equal 1, result.placements
    assert_equal "Mappa PosturaCorretta", map.title
    assert_equal [120.0, 340.0, true], [placement.x, placement.y, placement.collapsed]
    assert_equal 1, map.placements.count
  end

  test "rejects placements left in metro_maps.yml" do
    catalog = MetroMapCatalog.new(
      { "maps" => { "posturacorretta.org" => { "title" => "Mappa", "placements" => { "posturacorretta" => { "x" => 1, "y" => 2 } } } } }
    )

    error = assert_raises(ArgumentError) { catalog.validate! }
    assert_match "map_placements", error.message
  end

  test "reads the sessions and slots grid and rejects rows without coordinates" do
    grid = MetroMapCatalog.grid_for("posturacorretta.org", "test")
    assert_equal "Sessione", grid["column_label"]
    assert_equal "Slot 1 · Massaggio e recupero", grid["rows"].first["label"]

    catalog = MetroMapCatalog.new(
      { "maps" => { "posturacorretta.org" => { "title" => "Mappa", "grid" => { "first_x" => 0, "column_step" => 170, "rows" => [{ "label" => "Slot 1" }] } } } }
    )
    error = assert_raises(ArgumentError) { catalog.validate! }
    assert_match "griglia non valida", error.message
  end

  test "exports database placements inside node entries" do
    map = MetroMap.create!(domain: Domain.find_by!(hostname: "posturacorretta.org"), title: "Mappa")
    map.placements.create!(node: Node.find_by!(slug: "postura-e-fisiologia"), x: 10.123, y: 20, collapsed: true)
    source = <<~YAML
      default: &default
        nodes:
          postura-e-fisiologia:
            title: Postura e fisiologia
            map_placements:
              altro.org:
                x: 1
                y: 2

          posturacorretta:
            title: PosturaCorretta

      development:
        <<: *default
    YAML

    exported = MetroCatalogExporter.nodes_yaml(source)

    assert_equal <<~YAML, exported
      default: &default
        nodes:
          postura-e-fisiologia:
            title: Postura e fisiologia
            map_placements:
              posturacorretta.org:
                x: 10.12
                "y": 20.0
                collapsed: true

          posturacorretta:
            title: PosturaCorretta

      development:
        <<: *default
    YAML
  end
end
