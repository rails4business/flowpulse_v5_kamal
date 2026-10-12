require "test_helper"

class SkillProductTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "skill-product@example.com", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Product owner", username: "product_owner")
    assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
    node = Node.create!(title: "Brand", slug: "product-brand", role_assignment: assignment)
    skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")
    @activation = skill.reusable_skill_nodes.create!(node:, activated_by_profile: @profile)
  end

  test "belongs to a skill activation and generates its slug" do
    product = @activation.skill_products.create!(title: "Primo articolo", body: "# Testo", data: { "content_type" => "article" }, created_by_profile: @profile)

    assert_equal "primo-articolo", product.slug
    assert_equal "Contenuti", product.reusable_skill.title
    assert_equal "Brand", product.node.title
  end

  test "accepts only safe repository data paths" do
    product = @activation.skill_products.new(title: "File", created_by_profile: @profile, source_path: "../segreto.md")

    assert_not product.valid?
    assert_includes product.errors[:source_path], "non può uscire dalla repository"

    product.source_path = "config/data/brands/product-brand/contenuto.md"
    assert product.valid?
  end
end
