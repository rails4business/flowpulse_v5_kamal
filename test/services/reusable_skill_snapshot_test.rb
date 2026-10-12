require "test_helper"

class ReusableSkillSnapshotTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "skill-snapshot@example.com", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Skill snapshot", username: "skill_snapshot")
    @directory = Dir.mktmpdir("skills")
    @path = Pathname(@directory).join("skills.yml")
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "exports and imports definitions and dependencies" do
    contents = @profile.reusable_skills.create!(
      title: "Contenuti",
      category: "contents",
      status: "development",
      resource_type: "Content",
      documentation_markdown: "## Regole"
    )
    paths = @profile.reusable_skills.create!(title: "Percorsi", category: "paths", required_skills: [contents])
    snapshot = ReusableSkillSnapshot.new(owner_profile: @profile, path: @path)

    snapshot.export!
    contents.update!(title: "Titolo modificato")
    paths.reusable_skill_dependencies.delete_all

    assert_equal 2, snapshot.import!
    assert_equal "Contenuti", contents.reload.title
    assert_equal [contents], paths.reload.required_skills
  end

  test "import does not delete database-only skills" do
    @profile.reusable_skills.create!(title: "Contenuti", category: "contents")
    snapshot = ReusableSkillSnapshot.new(owner_profile: @profile, path: @path)
    snapshot.export!
    database_only = @profile.reusable_skills.create!(title: "Solo database", category: "other")

    snapshot.import!

    assert ReusableSkill.exists?(database_only.id)
  end
end
