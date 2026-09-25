require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "service@example.com", password: "password123", password_confirmation: "password123")
    profile = @user.create_profile!(display_name: "Service Owner")
    assignment = RoleAssignment.create!(profile: profile, role: :ideatore)
    @professional = Node.create!(title: "Test Professional", slug: "test-professional-service", node_type: :professional, role_assignment: assignment)
    @brand = Node.create!(title: "Test Brand", slug: "test-brand-service", parent: @professional, professional_owner_node: @professional, role_assignment: assignment)
    @project = Node.create!(title: "Test Project", slug: "test-project-service", parent: @brand, role_assignment: assignment)
  end

  test "belongs to any Node and exposes its label" do
    service = Service.create!(node: @project, created_by_user: @user, title: "Lezione", slug: "test-lezione")

    assert_equal "Test Project · Lezione", service.display_label
    assert_equal [service], @project.services.to_a
  end

  test "uses a slug unique inside its Node" do
    Service.create!(node: @brand, created_by_user: @user, title: "Gruppo", slug: "test-unique-service")
    duplicate = Service.new(node: @brand, created_by_user: @user, title: "Altro", slug: "test-unique-service")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "a public session requires a professional calendar but not a service" do
    experience = DataExperience.create!(created_by_user: @user, title: "Public calendar")
    data_session = DataSession.new(data_experience: experience, title: "Incomplete", visibility: "public", starts_at: 1.day.from_now)

    assert_not data_session.valid?
    assert data_session.errors[:professional_calendar].any?

    calendar = ProfessionalCalendar.create!(context_node: @project, professional_node: @professional, created_by_user: @user, title: "Gruppo", slug: "test-public-calendar", color: "sky")
    data_session.professional_calendar = calendar

    assert data_session.valid?
    assert_nil data_session.service
  end
end
