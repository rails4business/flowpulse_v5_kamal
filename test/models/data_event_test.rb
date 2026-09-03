require "test_helper"

class DataEventTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "data-event@example.com", password: "password123", password_confirmation: "password123")
    @profile = @user.create_profile!(display_name: "Mark Postura")
    @domain = Domain.create!(hostname: "data-event.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
  end

  test "builds the fixed root day session task hierarchy and inherits context" do
    root = create_event(title: "PosturaCorretta in un mese", node_kind: "root", classification: "course")
    day = create_event(title: "Martedì", node_kind: "day", parent: root, classification: nil, starts_at: Time.zone.parse("2026-09-08 15:00"))
    session = create_event(
      title: "Lezione settimanale",
      node_kind: "session",
      parent: day,
      classification: nil,
      starts_at: Time.zone.parse("2026-09-08 15:00"),
      ends_at: Time.zone.parse("2026-09-08 16:00")
    )
    task = create_event(title: "Mobilità articolare", node_kind: "task", parent: session, classification: nil)

    assert_equal "course", day.classification
    assert_equal @domain, task.effective_domain
    assert_equal @profile, task.effective_responsible_profile
    assert_equal [day], root.children.to_a
    assert_equal session, task.parent
  end

  test "rejects an invalid hierarchy" do
    root = create_event(title: "Corso", node_kind: "root", classification: "course")
    task = build_event(title: "Task fuori posto", node_kind: "task", parent: root, classification: nil)

    assert_not task.valid?
    assert_includes task.errors[:parent], "non è compatibile con il tipo di nodo"
  end

  test "only a service definition can be applied as service" do
    ordinary = create_event(title: "Corso ordinario", node_kind: "root", classification: "course")
    session = build_event(title: "Sessione", node_kind: "root", classification: "event", service_data_event: ordinary)

    assert_not session.valid?

    service = create_event(title: "Lezione Base", node_kind: "root", classification: "class", service_definition: true)
    session.service_data_event = service
    assert session.valid?
    assert session.separately_bookable?
  end

  test "draft cannot be public and a confirmed event can be published" do
    draft = build_event(title: "Bozza pubblica", node_kind: "root", classification: "event", visibility: "public")
    assert_not draft.valid?

    event = create_event(title: "Evento confermato", node_kind: "root", classification: "event", status: "confirmed")
    event.publish!

    assert_equal "public", event.visibility
    assert event.published_at.present?
    assert_includes DataEvent.published, event
  end

  test "organizer role is independent from domain and becomes the operational participation role" do
    teacher_event = create_event(
      title: "Lezione PosturaCorretta",
      operator_roles: [{ "role" => "teacher", "profile_id" => @profile.id }]
    )

    professional_user = User.create!(email_address: "wellness-professional@example.com", password: "password123", password_confirmation: "password123")
    professional = professional_user.create_profile!(display_name: "Professionista Benessere")
    wellness_domain = Domain.create!(hostname: "benessere-integrato.example", target_controller: "landing", target_action: "flowpulse", locale: "it")
    professional_event = DataEvent.create!(
      title: "Consulenza Benessere Integrato",
      classification: "event",
      node_kind: "root",
      domain: wellness_domain,
      created_by_profile: professional,
      responsible_profile: professional,
      operator_roles: [{ "role" => "professional", "profile_id" => professional.id }]
    )

    assert_equal @profile, teacher_event.organizer_profile
    assert_equal "teacher", teacher_event.organizer_participation_role
    assert_equal professional, professional_event.organizer_profile
    assert_equal "professional", professional_event.organizer_participation_role
  end

  test "sessions inherit the organizer role from their event tree" do
    root = create_event(
      title: "Corso",
      node_kind: "root",
      classification: "course",
      operator_roles: [{ "role" => "teacher", "profile_id" => @profile.id }]
    )
    day = create_event(title: "Giorno", node_kind: "day", parent: root, classification: nil)
    session = create_event(title: "Sessione", node_kind: "session", parent: day, classification: nil)

    assert_equal "teacher", session.organizer_participation_role
  end

  test "operator roles require one valid role per profile" do
    event = build_event(operator_roles: [{ "profile_id" => @profile.id }])

    assert_not event.valid?
    assert_includes event.errors[:operator_roles], "deve contenere ruolo e profilo di ogni operatore"
  end

  private

    def build_event(**attributes)
      DataEvent.new({
        title: "Evento",
        classification: "event",
        node_kind: "root",
        domain: @domain,
        created_by_profile: @profile,
        responsible_profile: @profile
      }.merge(attributes))
    end

    def create_event(**attributes)
      build_event(**attributes).tap(&:save!)
    end
end
