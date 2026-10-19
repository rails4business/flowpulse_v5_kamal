module DataExperiences
  class OrderedSteps
    TYPE_ORDER = {
      "commitment" => 0,
      "slot" => 1,
      "session" => 2
    }.freeze

    Entry = Data.define(:record, :kind, :position, :step_number)

    def initialize(data_experience, include_cancelled: true)
      @data_experience = data_experience
      @include_cancelled = include_cancelled
    end

    def call
      ordered_records.each_with_index.map do |record, index|
        Entry.new(
          record: record,
          kind: kind_for(record),
          position: record.position,
          step_number: index + 1
        )
      end
    end

    def position_collisions
      call.group_by(&:position).select { |_position, entries| entries.many? }
    end

    def next_position
      call.map(&:position).max.to_i + 10
    end

    private

      attr_reader :data_experience, :include_cancelled

      def ordered_records
        records = direct_commitments + top_level_slots + direct_sessions
        records.reject! { |record| record.status == "cancelled" } unless include_cancelled
        records.sort_by { |record| [record.position, TYPE_ORDER.fetch(kind_for(record)), record.id || 0] }
      end

      def direct_commitments
        data_experience.data_commitments
          .where(parent_id: nil, data_slot_id: nil, data_session_id: nil)
          .to_a
      end

      def top_level_slots
        data_experience.data_slots.includes(:data_session).select do |slot|
          slot.data_session.nil? || slot.data_session.data_experience_id != data_experience.id
        end
      end

      def direct_sessions
        data_experience.data_sessions.to_a
      end

      def kind_for(record)
        case record
        when Brands::Impegno::Commitment then "commitment"
        when DataSlot then "slot"
        when DataSession then "session"
        else
          raise ArgumentError, "Tipo di step non supportato: #{record.class.name}"
        end
      end
  end
end
