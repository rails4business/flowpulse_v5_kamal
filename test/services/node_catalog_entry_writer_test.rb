require "test_helper"

class NodeCatalogEntryWriterTest < ActiveSupport::TestCase
  test "updates one catalog entry without rewriting the remaining file" do
    user = User.create!(email_address: "catalog-writer@example.com", password: "password123", password_confirmation: "password123")
    user.create_profile!(display_name: "Catalog Writer", username: "catalog_writer")
    assignment = RoleAssignment.create!(profile: user.profile, role: :ideatore)
    node = Node.create!(
      title: "Catalog Writer Node",
      slug: "catalog-writer-node",
      role_assignment: assignment,
      status: "published",
      navigation: { "items" => [] }
    )
    path = Pathname(Dir.mktmpdir).join("nodes.yml")
    path.write("default: &default\n  nodes:\n    existing:\n      title: Existing\n\ndevelopment:\n  <<: *default\n")

    NodeCatalogEntryWriter.new(node, path: path).write!

    contents = path.read
    assert_includes contents, "    existing:"
    assert_includes contents, "    catalog-writer-node:"
    assert_includes contents, "navigation:"
    assert_includes contents, "development:"
  ensure
    FileUtils.remove_entry(path.dirname) if path&.dirname&.directory?
  end
end
