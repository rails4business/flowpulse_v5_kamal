require "test_helper"

class DataExperienceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "productive-experience@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @profile = @user.create_profile!(display_name: "Productive Experience", username: "productive_experience")
    assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
    @node = Node.create!(title: "Productive Brand", slug: "productive-brand", role_assignment: assignment)
    @process = NodeProcess.create!(node: @node, created_by_user: @user, title: "Produzione contenuti")
  end

  test "inherits the creator profile while retaining the legacy user" do
    experience = DataExperience.create!(created_by_user: @user, node_process: @process, title: "Primo prodotto")

    assert_equal @profile, @process.created_by_profile
    assert_equal @profile, experience.created_by_profile
    assert_equal "draft", experience.status
  end

  test "uses only an experience from the same process as reference" do
    reference = DataExperience.create!(created_by_user: @user, node_process: @process, title: "Riferimento")
    @process.update!(reference_data_experience: reference)

    other_process = NodeProcess.create!(node: @node, created_by_user: @user, title: "Altro processo")
    other_experience = DataExperience.create!(created_by_user: @user, node_process: other_process, title: "Altro prodotto")
    @process.reference_data_experience = other_experience

    assert_not @process.valid?
    assert_includes @process.errors[:reference_data_experience], "deve appartenere a questo processo"
  end

  test "connects at most one skill product and requires the same node as the process" do
    experience = DataExperience.create!(created_by_user: @user, node_process: @process, title: "Articolo")
    skill = @profile.reusable_skills.create!(title: "Contenuti", category: "contents")
    activation = skill.reusable_skill_nodes.create!(node: @node, activated_by_profile: @profile)
    product = activation.skill_products.create!(
      title: "Articolo",
      created_by_profile: @profile,
      data_experience: experience
    )

    assert_equal product, experience.reload.skill_product

    duplicate = activation.skill_products.new(
      title: "Duplicato",
      created_by_profile: @profile,
      data_experience: experience
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:data_experience_id].present?
  end

  test "allows a session shared by slots from different products" do
    first = DataExperience.create!(created_by_user: @user, node_process: @process, title: "Video A")
    second = DataExperience.create!(created_by_user: @user, node_process: @process, title: "Video B")
    shared_session = DataSession.create!(title: "Registrazione collettiva", created_by_profile: @profile)

    first_slot = DataSlot.create!(
      data_experience: first,
      data_session: shared_session,
      created_by_profile: @profile,
      title: "Registrazione Video A",
      position: 20
    )
    second_slot = DataSlot.create!(
      data_experience: second,
      data_session: shared_session,
      created_by_profile: @profile,
      title: "Registrazione Video B",
      position: 30
    )

    assert_nil shared_session.data_experience
    assert_equal [first_slot, second_slot], shared_session.data_slots.order(:id).to_a
  end
end
