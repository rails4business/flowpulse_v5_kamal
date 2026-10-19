module DataExperiences
  class Duplicate
    def initialize(source:, profile:, title: nil, node_process: source.node_process)
      @source = source
      @profile = profile
      @title = title.presence || "#{source.title} — copia"
      @node_process = node_process
    end

    def call
      DataExperience.transaction do
        duplicate_experience.tap do |copy|
          duplicate_direct_sessions(copy)
          duplicate_top_level_slots(copy)
          duplicate_direct_commitments(copy)
        end
      end
    end

    private

      attr_reader :source, :profile, :title, :node_process

      def duplicate_experience
        DataExperience.create!(
          created_by_user: profile.user,
          created_by_profile: profile,
          responsible_profile: profile,
          node_process: node_process,
          title: title,
          description: source.description,
          status: "draft"
        )
      end

      def duplicate_direct_sessions(copy)
        source.data_sessions.order(:position, :id).each do |data_session|
          session_copy = copy.data_sessions.create!(
            created_by_profile: profile,
            title: data_session.title,
            position: data_session.position,
            visibility: "private",
            service: data_session.service,
            status: "draft"
          )

          duplicate_session_commitments(data_session, copy, session_copy)
          data_session.data_slots.where(data_experience: source).order(:position, :id).each do |slot|
            duplicate_slot(slot, copy, session_copy)
          end
        end
      end

      def duplicate_top_level_slots(copy)
        source.data_slots.includes(:data_session).order(:position, :id).each do |slot|
          next if slot.data_session&.data_experience_id == source.id

          duplicate_slot(slot, copy, nil)
        end
      end

      def duplicate_slot(slot, copy, session_copy)
        slot_copy = copy.data_slots.create!(
          data_session: session_copy,
          created_by_profile: profile,
          title: slot.title,
          position: slot.position,
          status: "draft"
        )

        slot.data_commitments.where(parent_id: nil).order(:position, :id).each do |commitment|
          duplicate_commitment(commitment, copy, session_copy, slot_copy)
        end
      end

      def duplicate_session_commitments(data_session, copy, session_copy)
        data_session.data_commitments
          .where(data_slot_id: nil, parent_id: nil)
          .order(:position, :id)
          .each do |commitment|
            duplicate_commitment(commitment, copy, session_copy, nil)
          end
      end

      def duplicate_direct_commitments(copy)
        source.data_commitments
          .where(data_session_id: nil, data_slot_id: nil, parent_id: nil)
          .order(:position, :id)
          .each do |commitment|
            duplicate_commitment(commitment, copy, nil, nil)
          end
      end

      def duplicate_commitment(commitment, copy, session_copy, slot_copy, parent_copy = nil)
        commitment_copy = Brands::Impegno::Commitment.create!(
          profile: profile,
          created_by_profile: profile,
          assignee_profile: profile,
          responsible_profile: profile,
          domain: commitment.domain,
          subject: commitment.subject,
          parent: parent_copy,
          data_experience: copy,
          data_session: session_copy,
          data_slot: slot_copy,
          title: commitment.title,
          description: commitment.description,
          kind: commitment.kind,
          status: "draft",
          position: commitment.position,
          blocks_calendar: false,
          pricing_type: "none",
          contribution_type: "unpaid",
          publication_status: "draft",
          publication_visibility: "private",
          access_modes: commitment.access_modes
        )

        commitment.children.order(:position, :id).each do |child|
          duplicate_commitment(child, copy, session_copy, slot_copy, commitment_copy)
        end
      end
  end
end
