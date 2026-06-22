require "test_helper"

class NodeTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "creator@flowpulse.test", password: "password123", password_confirmation: "password123")
    @user.create_profile!(display_name: "Creator")
    @role_assignment = RoleAssignment.create!(profile: @user.profile, role: :creator_of_worlds)
    @node_a = Node.create!(title: "Node A", slug: "node-a", role_assignment: @role_assignment)
    @node_b = Node.create!(title: "Node B", slug: "node-b", role_assignment: @role_assignment, parent: @node_a)
  end

  test "should allow setting a valid link_node" do
    node_c = Node.new(
      title: "Bridge Node",
      slug: "bridge-node",
      role_assignment: @role_assignment,
      link_node: @node_a
    )
    assert node_c.valid?
  end

  test "cannot set link_node to self" do
    node = Node.create!(
      title: "Self Linker",
      slug: "self-linker",
      role_assignment: @role_assignment
    )
    node.link_node = node
    assert_not node.valid?
    assert_includes node.errors[:link_node_id], "non può essere il nodo stesso"
  end

  test "cannot set link_node from a different creator role assignment" do
    other_user = User.create!(email_address: "other@flowpulse.test", password: "password123", password_confirmation: "password123")
    other_user.create_profile!(display_name: "Other Creator")
    other_ra = RoleAssignment.create!(profile: other_user.profile, role: :creator_of_worlds)
    other_node = Node.create!(
      title: "Other Node",
      slug: "other-node",
      role_assignment: other_ra
    )

    node = Node.new(
      title: "Bridge to other",
      slug: "bridge-to-other",
      role_assignment: @role_assignment,
      link_node: other_node
    )
    assert_not node.valid?
    assert_includes node.errors[:link_node_id], "deve appartenere allo stesso Creatore"
  end

  test "cannot set link_node if the node already has children" do
    assert @node_a.children.any?
    @node_a.link_node = @node_b
    assert_not @node_a.valid?
    assert_includes @node_a.errors[:link_node_id], "non può essere impostato per un nodo che ha già dei figli"
  end

  test "cannot add a child to a bridge node" do
    bridge = Node.create!(
      title: "Bridge Node",
      slug: "bridge-node",
      role_assignment: @role_assignment,
      link_node: @node_a
    )
    assert bridge.bridge_node?

    child = Node.new(
      title: "Child of Bridge",
      slug: "child-of-bridge",
      role_assignment: @role_assignment,
      parent: bridge
    )
    assert_not child.valid?
    assert_includes child.errors[:parent_id], "non può essere un nodo ponte (i nodi ponte non possono avere figli)"
  end

  test "detects circular loops" do
    node_c = Node.create!(
      title: "Node C",
      slug: "node-c",
      role_assignment: @role_assignment
    )
    node_c.link_node = @node_b
    assert node_c.valid?
    node_c.save!

    @node_b.link_node = node_c
    assert_not @node_b.valid?
    assert_includes @node_b.errors[:link_node_id], "crea un ciclo/loop infinito di collegamenti"
  end

  test "resolves target correctly" do
    node_c = Node.create!(
      title: "Node C",
      slug: "node-c",
      role_assignment: @role_assignment,
      link_node: @node_b
    )
    @node_b.update!(link_node: @node_a)

    assert_equal @node_a, node_c.resolve_target
    assert_equal @node_a, @node_b.resolve_target
    assert_equal @node_a, @node_a.resolve_target
  end

  test "acts_as_list sorting scoped by role_assignment_id and parent_id" do
    node1 = Node.create!(title: "Node 1", role_assignment: @role_assignment)
    node2 = Node.create!(title: "Node 2", role_assignment: @role_assignment)
    assert_equal 2, node1.position
    assert_equal 3, node2.position

    other_user = User.create!(email_address: "other2@flowpulse.test", password: "password123", password_confirmation: "password123")
    other_user.create_profile!(display_name: "Other Creator 2")
    other_ra = RoleAssignment.create!(profile: other_user.profile, role: :creator_of_worlds)
    node_other = Node.create!(title: "Other 1", role_assignment: other_ra)
    assert_equal 1, node_other.position
  end

  test "syncs linked domains when role assignment changes" do
    domain = Domain.create!(hostname: "node-sync.example", node: @node_b, locale: "it")

    other_user = User.create!(email_address: "other-domain-sync@flowpulse.test", password: "password123", password_confirmation: "password123")
    other_user.create_profile!(display_name: "Other Domain Sync")
    other_ra = RoleAssignment.create!(profile: other_user.profile, role: :creator_of_worlds)

    @node_b.update!(role_assignment: other_ra, parent: nil)

    assert_equal other_ra.id, domain.reload.role_assignment_id
  end

  test "accepts free subscription visibility" do
    node = Node.new(
      title: "Free Subscription Node",
      role_assignment: @role_assignment,
      status: "published",
      visibility: "subscription"
    )

    assert node.valid?
    assert_equal "Iscrizione gratuita", Node.visibility_label("subscription")
  end
end
