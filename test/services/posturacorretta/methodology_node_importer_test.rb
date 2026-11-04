require "test_helper"

class Posturacorretta::MethodologyNodeImporterTest < ActiveSupport::TestCase
  setup do
    user = User.create!(
      email_address: "methodology-importer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_profile!(display_name: "Mark Postura", username: "markpostura")
    RoleAssignment.create!(profile: user.profile, role: :ideatore)
    NodeCatalog.from_config("test").import!
  end

  test "migrates every methodology and its structured content into canonical nodes" do
    importer = Posturacorretta::MethodologyNodeImporter.new

    first = importer.import!
    second = importer.import!

    container = Node.find_by!(slug: "metodiche-posturali")
    methodologies = container.children.order(:position)
    gds = Node.find_by!(slug: "gds")
    gds_content = gds.content

    assert_equal 9, first.nodes
    assert_equal 9, first.contents
    assert_equal first, second
    assert_equal 10, methodologies.size
    assert_equal (1..10).to_a, methodologies.pluck(:position)
    assert methodologies.all? { |node| node.view_type == "methodology" }
    assert methodologies.all? { |node| node.status == "published" && node.visibility == "public" }

    assert_equal "Biomeccanica Comportamentale GDS", gds.title
    assert_includes gds_content.body_md, "# Biomeccanica Comportamentale GDS"
    assert_equal "Godelieve Denys-Struyf", gds_content.data.dig("methodology", "founder")
    assert_equal %w[metodica-posturale tecnica-corporea-educativa], gds_content.data.dig("methodology", "typologies")
    assert_equal "config/data/posturacorretta/metodiche/contenuti/gds.md", gds_content.source_path
    assert_match(/\A[0-9a-f]{64}\z/, gds_content.source_checksum)
  end
end
