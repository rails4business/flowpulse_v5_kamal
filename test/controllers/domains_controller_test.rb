require "test_helper"

class DomainsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @creator_user = User.create!(
      email_address: "domains-dispatch@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @profile = @creator_user.create_profile!(display_name: "Dispatch Creator")
    @role_assignment = RoleAssignment.create!(
      profile: @profile,
      role: "creator_of_worlds"
    )
    @root_node = Node.create!(
      role_assignment: @role_assignment,
      title: "Creator Home Node",
      node_type: "node",
      status: "published"
    )
    # create a second node to test specific domain node vs creator home node
    @other_node = Node.create!(
      role_assignment: @role_assignment,
      title: "Specific Target Node",
      node_type: "node",
      status: "published"
    )
  end

  test "renders fallback home for unconfigured host" do
    get root_url

    assert_response :success
    assert_includes response.body, "Flowpulse"
  end

  test "renders configured domain target" do
    Domain.create!(hostname: "posturacorretta.org", target_controller: "landing", target_action: "posturacorretta", locale: "it")
    host! "posturacorretta.org"

    get root_url

    assert_response :success
    assert_includes response.body, "PosturaCorretta"
  end

  test "resolves current domain from forwarded host" do
    Domain.create!(hostname: "posturacorretta.org", target_controller: "landing", target_action: "posturacorretta", locale: "it")
    host! "internal.example"

    get root_url, headers: { "X-Forwarded-Host" => "posturacorretta.org" }

    assert_response :success
    assert_includes response.body, "PosturaCorretta"
  end

  test "resolves current domain when forwarded host includes port" do
    Domain.create!(hostname: "posturacorretta.org", target_controller: "landing", target_action: "posturacorretta", locale: "it")
    host! "internal.example"

    get root_url, headers: { "X-Forwarded-Host" => "posturacorretta.org:443" }

    assert_response :success
    assert_includes response.body, "PosturaCorretta"
  end

  test "renders configured controller target" do
    Domain.create!(hostname: "custom.org", target_controller: "landing", target_action: "flowpulse", locale: "it")
    host! "custom.org"

    get root_url

    assert_response :success
    assert_includes response.body, "Flowpulse"
  end

  test "redirects canonical domain aliases" do
    Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      locale: "it"
    )
    host! "www.posturacorretta.org"

    get root_url

    assert_redirected_to "http://posturacorretta.org/"
  end

  test "renders igiene posturale domain as posturacorretta landing" do
    Domain.create!(hostname: "igieneposturale.it", target_controller: "landing", target_action: "posturacorretta", locale: "it")
    host! "igieneposturale.it"

    get root_url

    assert_response :success
    assert_includes response.body, "PosturaCorretta"
  end

  test "prioritizes target_controller and target_action over node and creator" do
    # Domain has target_controller/action, node, and creator
    domain = Domain.create!(
      hostname: "all-in-one.org",
      target_controller: "landing",
      target_action: "posturacorretta",
      node: @other_node,
      role_assignment: @role_assignment,
      locale: "it"
    )
    host! "all-in-one.org"

    get root_url

    assert_response :success
    # Should render the landing page target_action "posturacorretta"
    assert_includes response.body, "PosturaCorretta"
    assert_not_includes response.body, "Specific Target Node"
    assert_not_includes response.body, "Creator Home Node"
  end

  test "prioritizes specific node over creator when target_controller/action is blank" do
    # Domain has node and creator, but no target_controller/action
    domain = Domain.create!(
      hostname: "node-and-creator.org",
      node: @other_node,
      role_assignment: @role_assignment,
      locale: "it"
    )
    host! "node-and-creator.org"

    get root_url

    assert_response :success
    # Should render the specific node
    assert_includes response.body, "Specific Target Node"
    assert_not_includes response.body, "Creator Home Node"
  end

  test "falls back to creator's first root node when target_controller/action and node are blank" do
    # Domain has creator only, no node and no target_controller/action
    domain = Domain.create!(
      hostname: "creator-only.org",
      role_assignment: @role_assignment,
      locale: "it"
    )
    host! "creator-only.org"

    get root_url

    assert_response :success
    # Should render the creator's first root node ("Creator Home Node")
    assert_includes response.body, "Creator Home Node"
    assert_not_includes response.body, "Specific Target Node"
  end
end
