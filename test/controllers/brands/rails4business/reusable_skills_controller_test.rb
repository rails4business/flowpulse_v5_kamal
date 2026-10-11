require "test_helper"

module Brands
  module Rails4business
    class ReusableSkillsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "skills@example.com", password: "password123", password_confirmation: "password123")
        @profile = @user.create_profile!(display_name: "Skills User", username: "skills_user")
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

      test "links a skill to a problem only when selected" do
        problem = @profile.problem_solving_cycles.create!(title: "Problema indipendente", status: "active")
        skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")

        patch rails4b_skill_url(skill), params: { reusable_skill: { title: skill.title, slug: skill.slug, category: skill.category, status: "development", problem_solving_cycle_ids: [problem.id] } }

        assert_equal "development", skill.reload.status
        assert_equal [problem], skill.problem_solving_cycles
      end
    end
  end
end
