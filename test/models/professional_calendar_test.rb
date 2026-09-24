require "test_helper"

class ProfessionalCalendarTest < ActiveSupport::TestCase
  test "belongs to a professional and any context Node" do
    user = User.create!(email_address: "professional-calendar@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Calendar Owner")
    assignment = RoleAssignment.create!(profile: profile, role: :ideatore)
    professional = Node.create!(title: "Calendar Professional", slug: "calendar-professional", professional: true, role_assignment: assignment)
    brand = Node.create!(title: "Calendar Brand", slug: "calendar-brand", parent: professional, professional_owner_node: professional, role_assignment: assignment)
    project = Node.create!(title: "Calendar Project", slug: "calendar-project", parent: brand, role_assignment: assignment)

    calendar = ProfessionalCalendar.create!(context_node: project, professional_node: professional, created_by_user: user, title: "Gruppo", slug: "calendar-group", color: "sky")

    assert_equal "Calendar Project · Gruppo", calendar.display_label
    assert_equal "Calendar Professional · Calendar Project · Gruppo", calendar.full_label
    assert_equal [calendar], professional.professional_calendars.to_a
    assert_equal [calendar], project.context_professional_calendars.to_a
  end

  test "the context Node resolves its closest site ancestor" do
    user = User.create!(email_address: "site-node@example.com", password: "password123", password_confirmation: "password123")
    profile = user.create_profile!(display_name: "Site Owner")
    assignment = RoleAssignment.create!(profile: profile, role: :ideatore)
    brand = Node.create!(title: "Site Brand", slug: "site-brand", role_assignment: assignment)
    project = Node.create!(title: "Site Project", slug: "site-project", parent: brand, role_assignment: assignment)
    Domain.create!(hostname: "site-node.test", locale: "it", node: brand, role_assignment: assignment, active: true)

    assert_equal brand, project.site_node
  end
end
