require "test_helper"

class NodeCatalogTest < ActiveSupport::TestCase
  setup do
    user = User.create!(
      email_address: "markpostura-catalog@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Mark Postura", username: "markpostura")
    RoleAssignment.create!(profile: user.profile, role: :ideatore)
  end

  test "imports the configured hierarchy and is idempotent" do
    catalog = NodeCatalog.from_config("test")

    first = catalog.import!
    second = catalog.import!

    mark = Node.find_by!(slug: "markpostura")
    postura = Node.find_by!(slug: "posturacorretta")

    assert_equal 4, first.nodes
    assert_equal 4, second.nodes
    assert_equal 4, Node.where(slug: %w[markpostura rails4business posturacorretta ilgiardinodelcorpo]).count
    assert mark.professional?
    assert_equal mark, user_profile.primary_node
    assert_equal mark, postura.parent
    assert_equal mark, postura.professional_owner_node
  end

  test "supports a professional demo without a profile association" do
    assignment = RoleAssignment.joins(:profile).find_by!(profiles: { username: "markpostura" })
    catalog = NodeCatalog.new(
      "nodes" => {
        "demo-professional" => {
          "title" => "Professionista non iscritto",
          "professional" => true,
          "owner_username" => "markpostura"
        }
      }
    )

    catalog.import!
    node = Node.find_by!(slug: "demo-professional")

    assert node.professional?
    assert_nil node.primary_professional_profile
    assert_equal assignment, node.role_assignment
  end

  test "dry run validates without persisting nodes" do
    catalog = NodeCatalog.from_config("test")

    assert_no_difference("Node.count") { catalog.import!(dry_run: true) }
  end

  private

    def user_profile
      Profile.find_by!(username: "markpostura")
    end
end
