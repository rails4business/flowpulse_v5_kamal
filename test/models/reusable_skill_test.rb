require "test_helper"

class ReusableSkillTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "skill-model@example.com", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Skill owner", username: "skill_owner")
  end

  test "generates a slug and keeps problems optional" do
    skill = @profile.reusable_skills.create!(title: "Corsi online", category: "courses")

    assert_equal "corsi-online", skill.slug
    assert_empty skill.problem_solving_cycles
  end

  test "can link a problem without merging the two records" do
    problem = @profile.problem_solving_cycles.create!(title: "Seguire un percorso", status: "active")
    skill = @profile.reusable_skills.create!(title: "Avanzamento corsi", category: "courses", problem_solving_cycles: [problem])

    assert_equal [problem], skill.problem_solving_cycles
    assert_equal [skill], problem.reusable_skills
  end

  test "can use another skill without becoming its child" do
    contents = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")
    paths = @profile.reusable_skills.create!(title: "Percorsi", category: "paths", required_skills: [contents])

    assert_equal [contents], paths.required_skills
    assert_equal [paths], contents.dependent_skills
  end

  test "cannot depend on itself" do
    skill = @profile.reusable_skills.create!(title: "Eventi", category: "events")
    dependency = skill.reusable_skill_dependencies.new(required_skill: skill)

    assert_not dependency.valid?
    assert_includes dependency.errors[:required_skill], "non può coincidere con la Skill"
  end
end
