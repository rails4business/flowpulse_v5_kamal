require "test_helper"

class DataEvents::PosturaCorrettaWeeklyScheduleTest < ActiveSupport::TestCase
  test "creates four alternatives for the same weekly lesson and is idempotent" do
    user = User.create!(email_address: "mark-weekly@example.com", password: "password123", password_confirmation: "password123")
    teacher = user.create_profile!(display_name: "Mark Postura", username: "mark_weekly")
    domain = Domain.create!(hostname: "weekly-posturacorretta.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
    place = Brands::Impegno::Place.create!(profile: teacher, domain: domain, name: "Viadana", kind: "center", scope: "domain", approval_status: "approved")
    service = DataEvents::PosturaCorrettaWeeklySchedule.new(
      week_start: Date.new(2026, 9, 7), domain: domain, teacher: teacher, place: place
    )

    first = service.call
    second = service.call

    assert_equal 4, first.fetch(:sessions).size
    assert_equal first.fetch(:sessions).map(&:id), second.fetch(:sessions).map(&:id)
    assert_equal [[2, 15], [2, 20], [4, 15], [4, 20]], first.fetch(:sessions).map { |event| [event.starts_at.to_date.cwday, event.starts_at.hour] }
    assert first.fetch(:sessions).all?(&:bookable?)
    assert first.fetch(:sessions).all? { |event| event.effective_service_data_event.service_definition? }
    assert_equal 2, first.fetch(:course).children.count
  end
end
