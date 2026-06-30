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

    test "domain context shows only current domain subtree and free roots" do
      current_root = Node.create!(title: "Postura Root", role_assignment: @assignment)
      current_child = Node.create!(title: "Postura Child", role_assignment: @assignment, parent: current_root)
      free_root = Node.create!(title: "Free Root", role_assignment: @assignment)
      other_root = Node.create!(title: "Other Root", role_assignment: @assignment)

      Domain.create!(hostname: "posturacorretta.test", locale: "it", role_assignment: @assignment, node: current_root)
      Domain.create!(hostname: "igieneposturale.test", locale: "it", role_assignment: @assignment, node: current_child)
      Domain.create!(hostname: "altro.test", locale: "it", role_assignment: @assignment, node: other_root)

      host! "posturacorretta.test"
      sign_in(@user)

      get tree_creator_world_role_assignment_node_url(@assignment, current_root)
      assert_response :success
      assert_includes response.body, "Postura Root"
      assert_includes response.body, "Postura Child"
      refute_includes response.body, "Other Root"
      refute_includes response.body, "Existing Node"

      get tree_creator_world_role_assignment_node_url(@assignment, free_root)
      assert_response :success
      assert_includes response.body, "Free Root"

      get tree_creator_world_role_assignment_node_url(@assignment, other_root)
      assert_redirected_to creator_world_root_url
    end

    test "domain context blocks moving nodes under another domain branch" do
      current_root = Node.create!(title: "Postura Root", role_assignment: @assignment)
      other_root = Node.create!(title: "Other Root", role_assignment: @assignment)
      moving_node = Node.create!(title: "Moving Node", role_assignment: @assignment, parent: current_root)

      Domain.create!(hostname: "posturacorretta.test", locale: "it", role_assignment: @assignment, node: current_root)
      Domain.create!(hostname: "altro.test", locale: "it", role_assignment: @assignment, node: other_root)

      host! "posturacorretta.test"
      sign_in(@user)

      patch move_creator_world_role_assignment_node_url(@assignment, moving_node),
        params: { parent_id: other_root.id, position: "last" }

      assert_response :unprocessable_entity
      assert_equal current_root.id, moving_node.reload.parent_id
    end

    test "domain context does not expose siblings of a nested domain root" do
      container = Node.create!(title: "Container Root", role_assignment: @assignment)
      current_root = Node.create!(title: "Postura Root", role_assignment: @assignment, parent: container)
      sibling = Node.create!(title: "Sibling Outside Domain", role_assignment: @assignment, parent: container)

      Domain.create!(hostname: "posturacorretta.test", locale: "it", role_assignment: @assignment, node: current_root)

      host! "posturacorretta.test"
      sign_in(@user)

      get tree_creator_world_role_assignment_node_url(@assignment, current_root)
      assert_response :success
      assert_includes response.body, "Postura Root"
      refute_includes response.body, "Container Root"
      refute_includes response.body, "Sibling Outside Domain"

      get tree_creator_world_role_assignment_node_url(@assignment, sibling)
      assert_redirected_to creator_world_root_url
    end

    test "domain context keeps completely unassigned root trees editable" do
      free_root = Node.create!(title: "Free Root", role_assignment: @assignment)
      free_child = Node.create!(title: "Free Child", role_assignment: @assignment, parent: free_root)
      domain_root = Node.create!(title: "Postura Root", role_assignment: @assignment)

      Domain.create!(hostname: "posturacorretta.test", locale: "it", role_assignment: @assignment, node: domain_root)

      host! "posturacorretta.test"
      sign_in(@user)

      get tree_creator_world_role_assignment_node_url(@assignment, free_child)
      assert_response :success
      assert_includes response.body, "Free Root"
      assert_includes response.body, "Free Child"
    end

    test "base domain context keeps creator tree unrestricted" do
      current_root = Node.create!(title: "Postura Root", role_assignment: @assignment)
      other_root = Node.create!(title: "Other Root", role_assignment: @assignment)

      Domain.create!(hostname: "flowpulse.net", locale: "it", role_assignment: @assignment, node: current_root)
      Domain.create!(hostname: "altro.test", locale: "it", role_assignment: @assignment, node: other_root)

      host! "flowpulse.net"
      sign_in(@user)

      get tree_creator_world_role_assignment_node_url(@assignment, current_root)
      assert_response :success
      assert_includes response.body, "Other Root"
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
