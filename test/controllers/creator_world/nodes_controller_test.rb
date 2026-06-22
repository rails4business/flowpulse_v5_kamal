require "test_helper"

module CreatorWorld
  class NodesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = create_user("creator-nodes@example.com")
      @assignment = RoleAssignment.create!(profile: @user.profile, role: :creator_of_worlds)
      @user.update!(active_role: :creator, current_role_assignment: @assignment)
      @node = Node.create!(title: "Existing Node", role_assignment: @assignment)
    end

    test "should get new with parent" do
      sign_in(@user)
      get new_creator_world_role_assignment_node_url(@assignment, parent_id: @node.id)

      assert_response :success
      assert_select ".flowtree-editor-shell"
      assert_includes response.body, "Nuovo nodo"
      assert_includes response.body, "Proprietà nota"
    end

    test "should get new without parent (new root node)" do
      sign_in(@user)
      get new_creator_world_role_assignment_node_url(@assignment)

      assert_response :success
      assert_select ".flowtree-editor-shell"
      assert_includes response.body, "Nuovo nodo"
    end

    # The layout tree view will be empty/nil check should not crash
    test "should get edit" do
      sign_in(@user)
      get edit_creator_world_role_assignment_node_url(@assignment, @node)

      assert_response :success
      assert_select ".flowtree-editor-shell"
      assert_includes response.body, "Existing Node"
      assert_includes response.body, "Proprietà nota"
    end

    test "cannot move a node under a bridge node" do
      target = Node.create!(title: "Target Node", role_assignment: @assignment)
      bridge = Node.create!(title: "Bridge Node", role_assignment: @assignment, link_node: target)
      child = Node.create!(title: "Moving Node", role_assignment: @assignment)

      sign_in(@user)
      patch move_creator_world_role_assignment_node_url(@assignment, child),
        params: { parent_id: bridge.id, position: "last" }

      assert_response :unprocessable_entity
      assert_nil child.reload.parent_id
    end

    private

    def create_user(email)
      User.create!(
        email_address: email,
        password: "password123",
        password_confirmation: "password123"
      ).tap do |user|
        user.create_profile!(display_name: email.split("@").first)
      end
    end

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
  end
end
