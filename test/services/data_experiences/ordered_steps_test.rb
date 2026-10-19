require "test_helper"

module DataExperiences
  class OrderedStepsTest < ActiveSupport::TestCase
    setup do
      @user = User.create!(
        email_address: "ordered-steps@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      @profile = @user.create_profile!(display_name: "Ordered Steps", username: "ordered_steps")
      assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
      node = Node.create!(title: "Ordered Brand", slug: "ordered-brand", role_assignment: assignment)
      process_record = NodeProcess.create!(node: node, created_by_user: @user, title: "Produzione video")
      @experience = DataExperience.create!(created_by_user: @user, node_process: process_record, title: "Video A")
      @domain = Domain.create!(
        hostname: "ordered-steps.example.test",
        locale: "it",
        target_controller: "home",
        target_action: "index",
        node: node
      )
    end

    test "merges only top-level commitments slots and sessions in recipe order" do
      direct_commitment = create_commitment(title: "Tema", position: 10)
      direct_slot = DataSlot.create!(
        data_experience: @experience,
        created_by_profile: @profile,
        title: "Testo",
        position: 20
      )
      shared_session = DataSession.create!(title: "Registrazione collettiva", created_by_profile: @profile)
      shared_slot = DataSlot.create!(
        data_experience: @experience,
        data_session: shared_session,
        created_by_profile: @profile,
        title: "Registrazione Video A",
        position: 30
      )
      direct_session = DataSession.create!(
        data_experience: @experience,
        created_by_profile: @profile,
        title: "Revisione",
        position: 40
      )
      nested_slot = DataSlot.create!(
        data_experience: @experience,
        data_session: direct_session,
        created_by_profile: @profile,
        title: "Controllo audio",
        position: 10
      )
      nested_commitment = create_commitment(
        title: "Eseguire il controllo",
        position: 1,
        data_slot: nested_slot,
        data_session: direct_session
      )

      entries = OrderedSteps.new(@experience).call

      assert_equal [direct_commitment, direct_slot, shared_slot, direct_session], entries.map(&:record)
      assert_equal %w[commitment slot slot session], entries.map(&:kind)
      assert_equal [1, 2, 3, 4], entries.map(&:step_number)
      assert_not_includes entries.map(&:record), nested_slot
      assert_not_includes entries.map(&:record), nested_commitment
    end

    test "reports positions shared by different top-level types" do
      create_commitment(title: "Tema", position: 10)
      DataSlot.create!(
        data_experience: @experience,
        created_by_profile: @profile,
        title: "Testo",
        position: 10
      )

      collisions = OrderedSteps.new(@experience).position_collisions

      assert_equal [10], collisions.keys
      assert_equal 2, collisions.fetch(10).size
    end

    private

      def create_commitment(title:, position:, data_slot: nil, data_session: nil)
        @profile.data_commitments.create!(
          created_by_profile: @profile,
          domain: @domain,
          data_experience: @experience,
          data_slot: data_slot,
          data_session: data_session,
          title: title,
          kind: "work",
          status: "draft",
          position: position,
          pricing_type: "none",
          contribution_type: "unpaid"
        )
      end
  end
end
