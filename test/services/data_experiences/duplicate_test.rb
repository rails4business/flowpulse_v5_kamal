require "test_helper"

module DataExperiences
  class DuplicateTest < ActiveSupport::TestCase
    setup do
      @user = User.create!(
        email_address: "duplicate-experience@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      @profile = @user.create_profile!(display_name: "Duplicate Experience", username: "duplicate_experience")
      assignment = RoleAssignment.create!(profile: @profile, role: :ideatore)
      node = Node.create!(title: "Duplicate Brand", slug: "duplicate-brand", role_assignment: assignment)
      @process = NodeProcess.create!(node: node, created_by_user: @user, title: "Produzione video")
      @domain = Domain.create!(
        hostname: "duplicate-experience.example.test",
        locale: "it",
        target_controller: "home",
        target_action: "index",
        node: node
      )
      @source = DataExperience.create!(
        created_by_user: @user,
        node_process: @process,
        title: "Video sorgente",
        description: "Ricetta verificata",
        status: "completed",
        started_at: Time.zone.parse("2026-10-01 09:00"),
        completed_at: Time.zone.parse("2026-10-02 18:00")
      )
    end

    test "copies the recipe types for the duplicating profile and clears planning data" do
      create_commitment(
        title: "Scegliere il tema",
        position: 10,
        starts_at: Time.zone.parse("2026-10-01 09:00"),
        ends_at: Time.zone.parse("2026-10-01 10:00")
      )
      direct_session = @source.data_sessions.create!(
        created_by_profile: @profile,
        title: "Revisione",
        position: 30,
        status: "completed",
        starts_at: Time.zone.parse("2026-10-02 10:00"),
        ends_at: Time.zone.parse("2026-10-02 11:00")
      )
      direct_session.data_slots.create!(
        data_experience: @source,
        created_by_profile: @profile,
        title: "Controllo audio",
        position: 10,
        status: "completed",
        starts_at: Time.zone.parse("2026-10-02 10:00"),
        ends_at: Time.zone.parse("2026-10-02 10:30")
      )
      shared_session = DataSession.create!(
        created_by_profile: @profile,
        title: "Registrazione collettiva",
        status: "completed",
        starts_at: Time.zone.parse("2026-10-01 14:00"),
        ends_at: Time.zone.parse("2026-10-01 18:00")
      )
      @source.data_slots.create!(
        data_session: shared_session,
        created_by_profile: @profile,
        title: "Registrazione Video sorgente",
        position: 20,
        status: "completed",
        starts_at: Time.zone.parse("2026-10-01 14:00"),
        ends_at: Time.zone.parse("2026-10-01 15:00")
      )

      copy = Duplicate.new(source: @source, profile: @profile, title: "Video nuovo").call

      assert_equal ["Video nuovo", "draft", @profile, @profile],
        [copy.title, copy.status, copy.created_by_profile, copy.responsible_profile]
      assert_nil copy.started_at
      assert_nil copy.completed_at

      copied_commitment = copy.data_commitments.find_by!(title: "Scegliere il tema")
      assert_equal ["draft", @profile, @profile, @profile],
        [copied_commitment.status, copied_commitment.profile, copied_commitment.assignee_profile, copied_commitment.responsible_profile]
      assert_nil copied_commitment.starts_at
      assert_nil copied_commitment.ends_at
      assert_equal "none", copied_commitment.pricing_type

      copied_session = copy.data_sessions.find_by!(title: "Revisione")
      assert_equal ["draft", @profile], [copied_session.status, copied_session.created_by_profile]
      assert_nil copied_session.starts_at
      assert_nil copied_session.ends_at

      copied_nested_slot = copy.data_slots.find_by!(title: "Controllo audio")
      assert_equal copied_session, copied_nested_slot.data_session
      assert_equal "draft", copied_nested_slot.status
      assert_nil copied_nested_slot.starts_at

      copied_shared_slot = copy.data_slots.find_by!(title: "Registrazione Video sorgente")
      assert_nil copied_shared_slot.data_session
      assert_equal "draft", copied_shared_slot.status
      assert_nil copied_shared_slot.starts_at
    end

    private

      def create_commitment(title:, position:, starts_at:, ends_at:)
        @profile.data_commitments.create!(
          created_by_profile: @profile,
          assignee_profile: @profile,
          responsible_profile: @profile,
          domain: @domain,
          data_experience: @source,
          title: title,
          kind: "work",
          status: "completed",
          position: position,
          starts_at: starts_at,
          ends_at: ends_at,
          pricing_type: "fixed",
          total_price: 100,
          contribution_type: "paid"
        )
      end
  end
end
