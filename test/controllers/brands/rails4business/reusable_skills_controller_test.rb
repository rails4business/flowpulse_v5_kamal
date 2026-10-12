require "test_helper"

module Brands
  module Rails4business
    class ReusableSkillsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "skills@example.com", password: "password123", password_confirmation: "password123")
        @profile = @user.create_profile!(display_name: "Skills User", username: "skills_user")
        assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
        @node = Node.create!(title: "Skill Brand", slug: "skill-brand", role_assignment: assignment)
        post session_url, params: { email_address: @user.email_address, password: "password123" }
      end

      test "creates and displays a reusable skill" do
        post rails4b_skills_url, params: { reusable_skill: { title: "Schede ed esercizi", category: "worksheets", description: "Schede configurabili dai Brand" } }

        skill = @profile.reusable_skills.find_by!(slug: "schede-ed-esercizi")
        assert_redirected_to rails4b_skill_url(skill)

        follow_redirect!
        assert_select "h1", text: "Schede ed esercizi"
        assert_select "option[selected]", text: "Schede ed esercizi"
      end

      test "creates a product for a skill activation" do
        skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")
        activation = skill.reusable_skill_nodes.create!(node: @node, activated_by_profile: @profile)

        post rails4b_skill_products_url(skill), params: {
          skill_product: {
            reusable_skill_node_id: activation.id,
            title: "Articolo di prova",
            body: "# Corpo",
            source_path: "config/data/brands/skill-brand/articolo.md",
            data_json: JSON.generate(content_type: "article")
          }
        }

        product = activation.skill_products.find_by!(slug: "articolo-di-prova")
        assert_redirected_to rails4b_skill_product_url(skill, product)
        assert_equal({ "content_type" => "article" }, product.data)
        assert_equal "config/data/brands/skill-brand/articolo.md", product.source_path
      end

      test "links a skill to a problem only when selected" do
        problem = @profile.problem_solving_cycles.create!(title: "Problema indipendente", status: "active")
        skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")

        patch rails4b_skill_url(skill), params: { reusable_skill: { title: skill.title, slug: skill.slug, category: skill.category, status: "development", problem_solving_cycle_ids: [problem.id] } }

        assert_equal "development", skill.reload.status
        assert_equal [problem], skill.problem_solving_cycles
      end

      test "stores documentation and links another skill as a dependency" do
        contents = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")
        paths = @profile.reusable_skills.create!(title: "Percorsi", category: "paths")

        patch rails4b_skill_url(paths), params: {
          reusable_skill: {
            title: paths.title,
            slug: paths.slug,
            category: paths.category,
            status: "development",
            resource_type: "LearningPath",
            documentation_markdown: "## Contratto",
            required_skill_ids: [contents.id]
          }
        }

        paths.reload
        assert_equal "LearningPath", paths.resource_type
        assert_equal "## Contratto", paths.documentation_markdown
        assert_equal [contents], paths.required_skills
      end
    end
  end
end
