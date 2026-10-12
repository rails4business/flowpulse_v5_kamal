require "test_helper"

class PublicSkillProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    user = User.create!(email_address: "public-product@example.com", password: "password123")
    profile = user.create_profile!(display_name: "Public Product")
    assignment = RoleAssignment.create!(profile:, role: :ideatore)
    node = Node.create!(title: "Product Brand", role_assignment: assignment, status: "published", visibility: "public")
    @domain = Domain.create!(hostname: "product.example", node:, role_assignment: assignment, locale: "it", site_title: "Product Example")
    skill = profile.reusable_skills.create!(title: "Contenuti", category: "contents", status: "available")
    activation = skill.reusable_skill_nodes.create!(node:, activated_by_profile: profile, status: "active")
    @product = activation.skill_products.create!(
      title: "Risorsa leggibile",
      status: "published",
      visibility: "public",
      body: "## Testo pubblico\n\nUna risorsa leggibile.",
      data: { "description" => "Descrizione della risorsa", "content_type" => "article" },
      created_by_profile: profile
    )
    host! @domain.hostname
  end

  test "renders a public product as indexable HTML with structured data" do
    get public_skill_product_url(@product, slug: @product.slug)

    assert_response :success
    assert_select "h1", text: "Risorsa leggibile"
    assert_select "h2", text: "Testo pubblico"
    assert_includes response.body, '"@type":"Article"'
    assert_not_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "does not expose a product requiring purchase" do
    @product.update!(visibility: "purchase")

    get public_skill_product_url(@product, slug: @product.slug)

    assert_response :not_found
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end
end
