require "test_helper"

module ContentEditing
  class NodeContentBackfillTest < ActiveSupport::TestCase
    setup do
      user = User.create!(email_address: "backfill@example.test", password: "password123", password_confirmation: "password123")
      profile = user.create_profile!(display_name: "Backfill", username: "backfill")
      @role = RoleAssignment.create!(profile:, role: :creator_of_worlds)
    end

    test "creates show Content from legacy markdown without deleting NodeContent" do
      node = Node.create!(title: "Lezione", slug: "lezione-backfill", role_assignment: @role,
        content_attributes: { editor: "markdown", format: "markdown", body_md: "# Corpo legacy" })

      result = NodeContentBackfill.new(node).call

      assert_equal result.content, node.reload.show_content
      assert_equal "# Corpo legacy", result.content.body_md
      assert_includes result.content.body.to_s, "Corpo legacy"
      assert node.content.persisted?
      assert_equal "created", result.action
    end

    test "links an existing course Content instead of duplicating it" do
      brand_node = Node.create!(title: "Brand", slug: "brand-backfill", role_assignment: @role)
      course_node = Node.create!(title: "Corso", slug: "corso-backfill", role_assignment: @role,
        parent: brand_node, view_type: "course")
      lesson_node = Node.create!(title: "Lezione", slug: "lezione-corso-backfill", role_assignment: @role,
        parent: course_node, view_type: "course_lesson")
      course = Content.create!(node: brand_node, key: "corso-esistente", slug: "corso-esistente",
        format: "course", title: "Corso esistente")
      course.children.create!(node: lesson_node, key: "capitolo-esistente", slug: "capitolo",
        format: "chapter", title: "Capitolo")
      content_count = Content.count

      result = NodeContentBackfill.new(course_node).call

      assert_equal course, result.content
      assert_equal course, course_node.reload.show_content
      assert course_node.outgoing_content_links.exists?(target_content: course, kind: "show")
      assert_equal content_count, Content.count
    end
  end
end
