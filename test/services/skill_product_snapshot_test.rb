require "test_helper"

class SkillProductSnapshotTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "product-snapshot@example.com", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Product snapshot", username: "product_snapshot")
    assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
    node = Node.create!(title: "Snapshot Brand", slug: "snapshot-brand", role_assignment: assignment)
    skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")
    @activation = skill.reusable_skill_nodes.create!(node:, activated_by_profile: @profile)
    @directory = Pathname(Dir.mktmpdir("skill-products"))
    @catalog_path = @directory.join("skill_products.yml")
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "exports Markdown to source path and restores the database product" do
    product = @activation.skill_products.create!(title: "Articolo", body: "# Versione repository", data: { "content_type" => "article" }, source_path: "config/data/brands/snapshot-brand/articolo.md", created_by_profile: @profile)
    snapshot = SkillProductSnapshot.new(owner_profile: @profile, path: @catalog_path, repository_root: @directory)

    snapshot.export!
    assert_equal "# Versione repository", @directory.join(product.source_path).read

    product.update!(body: "Testo modificato", data: {})
    assert_equal 1, snapshot.import!
    assert_equal "# Versione repository", product.reload.body
    assert_equal({ "content_type" => "article" }, product.data)
  end
end
