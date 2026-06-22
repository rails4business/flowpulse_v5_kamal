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
end
