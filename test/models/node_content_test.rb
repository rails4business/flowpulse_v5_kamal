require "test_helper"

class NodeContentTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "creator_test@flowpulse.test", password: "password123", password_confirmation: "password123")
    @user.create_profile!(display_name: "Creator Test")
    @role_assignment = RoleAssignment.create!(profile: @user.profile, role: :creator_of_worlds)
    @node = Node.create!(title: "Test Node", slug: "test-node", role_assignment: @role_assignment)
  end

  test "should set default editor and format if blank" do
    @node.content&.destroy!
    content = NodeContent.create!(node: @node)
    assert_equal "markdown", content.editor
    assert_equal "markdown", content.format
    assert_equal({}, content.body_json)
    assert_equal({}, content.data)
  end

  test "should enforce uniqueness of node_id" do
    # When creating a node, Node builds a default content on initialize.
    # Let's clean the existing content to test uniqueness
    @node.content&.destroy!

    content1 = NodeContent.create!(node: @node)
    content2 = NodeContent.new(node: @node)

    assert_not content2.valid?
    assert_includes content2.errors[:node_id], "has already been taken"
  end

  test "prepares existing markdown for Lexxy without changing the stored source" do
    content = @node.content
    content.update!(body_md: "# Titolo\n\nTesto **importante**.")

    content.prepare_lexxy_body!

    assert_includes content.body.to_s, "<h1>Titolo</h1>"
    assert_includes content.body.to_s, "<strong>importante</strong>"
    assert_equal "# Titolo\n\nTesto **importante**.", content.body_md
    assert_not content.body.persisted?
  end

  test "saves Lexxy HTML as the original and derives a Markdown copy" do
    content = @node.content
    content.assign_attributes(
      editor: "lexxy",
      format: "html",
      body: "<h2>Sezione</h2><p>Testo <strong>importante</strong>.</p>"
    )
    content.save!

    assert_equal "html", content.format
    assert_includes content.body_html, "<h2>Sezione</h2>"
    assert_equal "## Sezione\n\nTesto **importante**.", content.body_md
    assert content.reload.body.present?
  end

  test "saves Lexxy content through Node nested attributes" do
    @node.update!(
      content_attributes: {
        id: @node.content.id,
        editor: "lexxy",
        format: "html",
        body: "<p>Contenuto dal form</p>"
      }
    )

    content = @node.reload.content
    assert_equal "Contenuto dal form", content.body.to_plain_text
    assert_equal "Contenuto dal form", content.body_md
  end
end
