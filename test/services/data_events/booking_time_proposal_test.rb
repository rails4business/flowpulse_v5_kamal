require "test_helper"

module DataEvents
  class BookingTimeProposalTest < ActiveSupport::TestCase
    setup do
      user = User.create!(email_address: "booking-proposal@example.com", password: "password123", password_confirmation: "password123")
      @organizer = user.create_profile!(display_name: "Organizzatore")
      @domain = Domain.create!(hostname: "booking-proposal.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
      @root = create_event(title: "Disponibilità", node_kind: "root", classification: "event")
      @day = create_event(title: "Pomeriggio", node_kind: "day", parent: @root, starts_at: at(15), ends_at: at(18))
    end

    test "proposes the beginning of an empty window" do
      assert_equal [at(15)...at(16)], proposals(@day)
    end

    test "proposes compact intervals immediately before and after an existing session" do
      create_event(title: "Prenotata", node_kind: "session", parent: @day, starts_at: at(16), ends_at: at(17))

      assert_equal [at(15)...at(16), at(17)...at(18)], proposals(@day)
    end

    test "keeps another window on the same date separate" do
      evening = create_event(title: "Sera", node_kind: "day", parent: @root, starts_at: at(18), ends_at: at(21))
      create_event(title: "Altra fascia", node_kind: "session", parent: evening, starts_at: at(18), ends_at: at(19))

      assert_equal [at(15)...at(16)], proposals(@day)
    end

    test "returns no proposal when the window is full or duration is unavailable" do
      create_event(title: "Prima", node_kind: "session", parent: @day, starts_at: at(15), ends_at: at(17))
      create_event(title: "Seconda", node_kind: "session", parent: @day, starts_at: at(17), ends_at: at(18))

      assert_empty proposals(@day)
      assert_empty BookingTimeProposal.new(day: @day, duration_minutes: nil).call
    end

    test "allows multiple windows on one date but rejects overlapping siblings" do
      morning = build_event(title: "Mattina", node_kind: "day", parent: @root, starts_at: at(9), ends_at: at(12))
      assert morning.valid?

      overlapping = build_event(title: "Sovrapposta", node_kind: "day", parent: @root, starts_at: at(17), ends_at: at(19))
      assert_not overlapping.valid?
      assert_includes overlapping.errors[:starts_at], "si sovrappone a un'altra fascia dello stesso giorno"
    end

    private

      def proposals(day)
        BookingTimeProposal.new(day:, duration_minutes: 60).call
      end

      def at(hour)
        Time.zone.local(2026, 9, 8, hour)
      end

      def build_event(**attributes)
        DataEvent.new({
          title: "Evento", classification: "event", node_kind: "root", domain: @domain,
          created_by_profile: @organizer, responsible_profile: @organizer,
          operator_roles: [{ "role" => "professional", "profile_id" => @organizer.id }]
        }.merge(attributes))
      end

      def create_event(**attributes)
        build_event(**attributes).tap(&:save!)
      end
  end
end
