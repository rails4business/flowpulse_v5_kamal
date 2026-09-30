require "test_helper"
require "tmpdir"

class BrandNodeSnapshotTest < ActiveSupport::TestCase
  setup do
    owner = User.create!(email_address: "snapshot-owner@example.com", password: "password123", password_confirmation: "password123")
    profile = owner.create_profile!(display_name: "Snapshot Owner")
    role = RoleAssignment.create!(profile:, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: role, title: "Snapshot Brand", slug: "snapshot-brand", status: "published")
    Domain.create!(hostname: "snapshot-brand.test", node: @brand, role_assignment: role, active: true)
    @child = Node.create!(parent: @brand, title: "Percorso online", slug: "percorso-online", description: "Versione nello YAML")
    @directory = Dir.mktmpdir("brand-node-snapshot")
    @path = Pathname(@directory).join("nodes.yml")
  end

  teardown do
    FileUtils.remove_entry(@directory) if @directory && File.exist?(@directory)
  end

  test "exports and restores the Brand tree without deleting other nodes" do
    snapshot = BrandNodeSnapshot.new(brand: @brand, path: @path)
    snapshot.export!
    @child.update!(description: "Modificata nel database")
    extra = Node.create!(parent: @brand, title: "Solo database", slug: "solo-database")

    assert_equal 2, snapshot.import!

    assert_equal "Versione nello YAML", @child.reload.description
    assert extra.reload.persisted?
    assert_equal "snapshot-brand", YAML.safe_load_file(@path, permitted_classes: [], aliases: false).fetch("brand")
  end

  test "dry run validates and rolls back changes" do
    snapshot = BrandNodeSnapshot.new(brand: @brand, path: @path)
    snapshot.export!
    @child.update!(title: "Titolo locale")

    assert_equal 2, snapshot.import!(dry_run: true)
    assert_equal "Titolo locale", @child.reload.title
  end
end
