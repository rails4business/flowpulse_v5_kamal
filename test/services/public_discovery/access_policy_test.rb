require "test_helper"

module PublicDiscovery
  class AccessPolicyTest < ActiveSupport::TestCase
    setup do
      user = User.create!(email_address: "public-policy@example.com", password: "password123")
      @profile = user.create_profile!(display_name: "Public Policy")
      assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
      @node = Node.create!(title: "Public Brand", role_assignment: assignment, status: "published", visibility: "public")
      @domain = Domain.create!(hostname: "public-policy.example", node: @node, role_assignment: assignment, locale: "it")
      @policy = AccessPolicy.new
    end

    test "a domain is public only through an active canonical published and public root" do
      assert @policy.public_domain?(@domain)

      @node.update!(visibility: "subscription")
      assert_not @policy.public_domain?(@domain)

      @node.update!(visibility: "public", status: "draft")
      assert_not @policy.public_domain?(@domain)
    end

    test "a skill product requires a public branch an active activation and an available skill" do
      skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents", status: "available")
      activation = skill.reusable_skill_nodes.create!(node: @node, activated_by_profile: @profile, status: "active")
      product = activation.skill_products.create!(
        title: "Risorsa pubblica",
        status: "published",
        visibility: "public",
        body: "Testo",
        created_by_profile: @profile
      )

      assert @policy.public_skill_product?(product, domain: @domain)

      product.update!(visibility: "purchase")
      assert_not @policy.public_skill_product?(product, domain: @domain)
    end
  end
end
