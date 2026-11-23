require "test_helper"

class MetroLineCatalogTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "line-catalog@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Line Catalog", username: "markpostura")
    RoleAssignment.create!(profile:, role: :ideatore)
    NodeCatalog.from_config("test").import!
    root = Node.find_by!(slug: "posturacorretta")
    Domain.create!(hostname: "posturacorretta.org", node: root, role_assignment: root.role_assignment, active: true, primary: true)
  end

  test "imports the explicitly ordered compatibility line idempotently" do
    catalog = MetroLineCatalog.from_config("test")

    first = catalog.import!
    second = catalog.import!
    line = MetroLine.find_by!(slug: "postura-recupero")

    assert_equal 1, first.lines
    assert_equal first, second
    assert_equal "corso-introduzione-al-percorso-integrato", line.ordered_nodes.first.slug
    assert_equal "altre-metodiche-posturali-sintesi-percorso", line.ordered_nodes.last.slug
    assert_equal 45, line.ordered_nodes.size
  end
end
