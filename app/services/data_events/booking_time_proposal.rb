module DataEvents
  class BookingTimeProposal
    def initialize(day:, duration_minutes:)
      @day = day
      @duration_minutes = Integer(duration_minutes, exception: false)
    end

    def call
      return [] unless valid_window?

      occupied = occupied_intervals
      adjacent = day.children.where(node_kind: "session").where.not(starts_at: nil, ends_at: nil).map { |session| session.starts_at...session.ends_at }
      return [window_start...window_end_for(window_start)] if adjacent.empty? && fits?(window_start, occupied:)

      adjacent
        .flat_map { |interval| [interval.begin - duration, interval.end] }
        .uniq
        .select { |starts_at| fits?(starts_at, occupied:) }
        .sort
        .map { |starts_at| starts_at...window_end_for(starts_at) }
    end

    private

      attr_reader :day, :duration_minutes

      def valid_window?
        day.node_kind == "day" && day.starts_at.present? && day.ends_at.present? &&
          duration_minutes.present? && duration_minutes.positive?
      end

      def duration
        duration_minutes.minutes
      end

      def window_start
        day.starts_at
      end

      def window_end
        day.ends_at
      end

      def window_end_for(starts_at)
        starts_at + duration
      end

      def fits?(starts_at, occupied: [])
        candidate_end = window_end_for(starts_at)
        return false if starts_at < window_start || candidate_end > window_end

        occupied.none? { |interval| starts_at < interval.end && interval.begin < candidate_end }
      end

      def occupied_intervals
        sibling_days = DataEvent
          .where(parent_id: day.parent_id, node_kind: "day")
          .where(starts_at: window_start.beginning_of_day..window_start.end_of_day)

        organizer_id = day.organizer_profile&.id
        DataEvent
          .where(parent_id: sibling_days.select(:id), node_kind: "session")
          .where.not(starts_at: nil, ends_at: nil)
          .chronological
          .select { |session| organizer_id.blank? || session.organizer_profile&.id == organizer_id }
          .map { |session| session.starts_at...session.ends_at }
      end
  end
end
