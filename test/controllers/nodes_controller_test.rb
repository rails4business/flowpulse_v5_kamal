require "test_helper"

class NodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "public-node-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @user.create_profile!(display_name: "Public Node Creator")
    @assignment = RoleAssignment.create!(profile: @user.profile, role: :creator_of_worlds)
    @user.update!(active_role: :creator, current_role_assignment: @assignment)
    @draft_node = Node.create!(
      title: "Draft Node",
      role_assignment: @assignment,
      status: "draft",
      visibility: "public"
    )
    @draft_node.content.update!(body_md: "Draft body")
    @published_node = Node.create!(
      title: "Published Node",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    @published_node.content.update!(body_md: "Published body")
  end

  test "public visitor cannot view draft node" do
    get node_url(@draft_node)

    assert_redirected_to root_url
  end

  test "public visitor can view published node" do
    get node_url(@published_node)

    assert_response :success
    assert_includes response.body, "Published Node"
    assert_select "aside#bookAside", false
    assert_no_match "Indice del Libro", response.body
    assert_no_match "Anteprima privata", response.body
    assert_select ".node-public-status", false
  end

  test "public visitor cannot view free subscription node" do
    subscription_node = Node.create!(
      title: "Subscriber Lesson",
      role_assignment: @assignment,
      status: "published",
      visibility: "subscription"
    )
    subscription_node.content.update!(body_md: "Only subscribers can read this.")

    get node_url(subscription_node)

    assert_redirected_to root_url
  end

  test "traveler with ancestor domain subscription can view free subscription node" do
    traveler = User.create!(
      email_address: "free-subscription-traveler@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    traveler.create_profile!(display_name: "Free Traveler")
    root = Node.create!(
      title: "Subscription Domain Root",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    subscription_node = Node.create!(
      title: "Subscriber Lesson",
      role_assignment: @assignment,
      parent: root,
      status: "published",
      visibility: "subscription"
    )
    subscription_node.content.update!(body_md: "Only subscribers can read this.")
    domain = Domain.create!(
      hostname: "free-subscription.example",
      node: root,
      role_assignment: @assignment,
      locale: "it"
    )
    TravelerSubscription.create!(profile: traveler.profile, domain: domain)
    sign_in(traveler)

    get node_url(subscription_node)

    assert_response :success
    assert_includes response.body, "Subscriber Lesson"
    assert_includes response.body, "Only subscribers can read this."
  end

  test "left sidebar hides free subscription child until traveler is subscribed" do
    traveler = User.create!(
      email_address: "sidebar-free-subscription-traveler@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    traveler.create_profile!(display_name: "Sidebar Traveler")
    root = Node.create!(
      title: "Sidebar Domain Root",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    public_child = Node.create!(
      title: "Open Child",
      role_assignment: @assignment,
      parent: root,
      status: "published",
      visibility: "public"
    )
    subscription_child = Node.create!(
      title: "Subscriber Child",
      role_assignment: @assignment,
      parent: root,
      status: "published",
      visibility: "subscription"
    )
    domain = Domain.create!(
      hostname: "sidebar-free-subscription.example",
      node: root,
      role_assignment: @assignment,
      locale: "it"
    )

    get node_url(root)

    assert_response :success
    assert_select ".node-public-sidebar-link[href=?]", node_path(public_child), text: "Open Child"
    assert_select ".node-public-sidebar-link[href=?]", node_path(subscription_child), count: 0

    TravelerSubscription.create!(profile: traveler.profile, domain: domain)
    sign_in(traveler)

    get node_url(root)

    assert_response :success
    assert_select ".node-public-sidebar-link[href=?]", node_path(public_child), text: "Open Child"
    assert_select ".node-public-sidebar-link[href=?]", node_path(subscription_child), text: "Subscriber Child"
  end

  test "domain node show redirects to configured target action" do
    Domain.create!(
      hostname: "target-node.example",
      node: @published_node,
      role_assignment: @assignment,
      target_controller: "landing",
      target_action: "posturacorretta",
      locale: "it"
    )

    get node_url(@published_node)

    assert_redirected_to posturacorretta_path
  end

  test "traveler sees subscribe action on domain node" do
    traveler = User.create!(
      email_address: "node-domain-traveler@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    traveler.create_profile!(display_name: "Node Traveler")
    Domain.create!(
      hostname: "node-subscribe.example",
      node: @published_node,
      role_assignment: @assignment,
      locale: "it"
    )
    post session_url, params: { email_address: traveler.email_address, password: "password123" }

    get node_url(@published_node)

    assert_response :success
    assert_select "header form[action=?]", traveler_subscriptions_path
    assert_select "header details summary.rounded-full", text: /N/
    assert_select "header details a[href=?]", dashboard_path, text: "Dashboard"
    assert_operator response.body.index("Iscriviti gratis"), :<, response.body.index("node-public-breadcrumb")
    assert_includes response.body, "Iscriviti gratis"
  end

  test "public visitor sees free subscribe link on domain node" do
    domain = Domain.create!(
      hostname: "anonymous-subscribe.example",
      node: @published_node,
      role_assignment: @assignment,
      locale: "it"
    )

    get node_url(@published_node)

    assert_response :success
    assert_select "header a[href=?]", new_user_path(subscription_domain_id: domain.id, return_to: node_path(@published_node)), text: "Iscriviti gratis"
  end

  test "traveler sees subscribe action on nodes inside a navigation domain" do
    traveler = User.create!(
      email_address: "node-domain-child-traveler@example.com",
      password: "password123",
      password_confirmation: "password123",
      active_role: :traveler
    )
    traveler.create_profile!(display_name: "Child Traveler")
    root = Node.create!(
      title: "Domain Root",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    child = Node.create!(
      title: "Domain Child",
      role_assignment: @assignment,
      parent: root,
      status: "published",
      visibility: "public"
    )
    domain = Domain.create!(
      hostname: "child-subscribe.example",
      node: root,
      role_assignment: @assignment,
      locale: "it"
    )
    post session_url, params: { email_address: traveler.email_address, password: "password123" }

    get node_url(child)

    assert_response :success
    assert_select "header form[action=?]", traveler_subscriptions_path do
      assert_select "input[name='domain_id'][value=?]", domain.id.to_s
    end
    assert_operator response.body.index("Iscriviti gratis"), :<, response.body.index("node-public-breadcrumb")
  end

  test "creator can preview own draft node" do
    sign_in(@user)

    get node_url(@draft_node)

    assert_response :success
    assert_includes response.body, "Draft Node"
    assert_not_includes response.body, "Anteprima privata"
    assert_select ".node-public-status", false
    assert_select ".node-public-creator-menu-toggle"
    assert_includes response.body, "Creator"
    assert_includes response.body, "Stato"
    assert_includes response.body, "draft"
    assert_includes response.body, "Visibilita"
    assert_includes response.body, "Pubblico"
    assert_includes response.body, dashboard_path
    assert_no_match admin_dashboard_path, response.body
  end

  test "domain navigation does not climb above domain root node" do
    top_root = Node.create!(
      title: "Top Root",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    domain_root = Node.create!(
      title: "Domain Root",
      role_assignment: @assignment,
      parent: top_root,
      status: "published",
      visibility: "public"
    )
    external_sibling = Node.create!(
      title: "External Sibling",
      role_assignment: @assignment,
      parent: top_root,
      status: "published",
      visibility: "public"
    )
    child = Node.create!(
      title: "Domain Child",
      role_assignment: @assignment,
      parent: domain_root,
      status: "published",
      visibility: "public"
    )
    sibling = Node.create!(
      title: "Domain Sibling",
      role_assignment: @assignment,
      parent: domain_root,
      status: "published",
      visibility: "public"
    )
    Domain.create!(
      hostname: "www.bounded.example",
      node: domain_root,
      role_assignment: @assignment,
      locale: "it",
      logo_full_url: "https://cdn.example.com/bounded-full.png",
      logo_square_url: "https://cdn.example.com/bounded-square.png"
    )

    host! "www.bounded.example"
    get node_url(child)

    assert_response :success
    assert_select "aside#bookAside", false
    assert_select "link[rel='icon'][href='https://cdn.example.com/bounded-square.png']"
    assert_select "link[rel='apple-touch-icon'][href='https://cdn.example.com/bounded-square.png']"
    assert_select ".node-public-breadcrumb a .node-public-breadcrumb-logo-full[src='https://cdn.example.com/bounded-full.png'][alt='bounded.example']"
    assert_select ".node-public-breadcrumb a .node-public-breadcrumb-logo-square[src='https://cdn.example.com/bounded-square.png'][alt='bounded.example']"
    assert_select ".node-public-breadcrumb a .sr-only", "bounded.example"
    assert_select ".node-public-reading-nav-static"
    assert_no_match "www.bounded.example", response.body
    assert_no_match "Top Root", response.body
    assert_includes response.body, "bounded.example"
    assert_includes response.body, "Domain Sibling"
    assert_no_match "Indice del Libro", response.body

    get node_url(domain_root)

    assert_response :success
    assert_select ".node-public-breadcrumb-current .node-public-breadcrumb-logo-full[src='https://cdn.example.com/bounded-full.png'][alt='bounded.example']"
    assert_select ".node-public-breadcrumb-current .node-public-breadcrumb-logo-square[src='https://cdn.example.com/bounded-square.png'][alt='bounded.example']"
    assert_select "aside#bookAside", false
    assert_no_match "Top Root", response.body
    assert_select ".node-public-reading-nav-static"
    assert_select ".node-public-book-down[href=?]", node_path(child)
    assert_select ".node-public-book-up", false
    assert_select ".node-public-sidebar-link[href=?]", node_path(external_sibling), count: 0
    assert_select ".node-public-sidebar-link[href=?]", node_path(child), text: "Domain Child"
    assert_select ".node-public-sidebar-link[href=?]", node_path(sibling), text: "Domain Sibling"
  end

  test "domain root shows siblings when reached from parent domain host" do
    top_root = Node.create!(
      title: "Top Root",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    domain_root = Node.create!(
      title: "Nested Domain Root",
      role_assignment: @assignment,
      parent: top_root,
      status: "published",
      visibility: "public"
    )
    sibling = Node.create!(
      title: "Nested Domain Sibling",
      role_assignment: @assignment,
      parent: top_root,
      status: "published",
      visibility: "public"
    )
    child = Node.create!(
      title: "Nested Domain Child",
      role_assignment: @assignment,
      parent: domain_root,
      status: "published",
      visibility: "public"
    )
    Domain.create!(
      hostname: "parent-domain.example",
      node: top_root,
      role_assignment: @assignment,
      locale: "it"
    )
    Domain.create!(
      hostname: "nested-domain.example",
      node: domain_root,
      role_assignment: @assignment,
      locale: "it"
    )

    host! "parent-domain.example"
    get node_url(domain_root)

    assert_response :success
    assert_select ".node-public-breadcrumb a", "parent-domain.example"
    assert_select ".node-public-sidebar-parent-link[href=?]", node_path(top_root), text: "Top Root"
    assert_select ".node-public-sidebar-link[href=?]", node_path(domain_root), text: "Nested Domain Root"
    assert_select ".node-public-sidebar-link[href=?]", node_path(sibling), text: "Nested Domain Sibling"
    assert_select ".node-public-sidebar-sublink[href=?]", node_path(child), text: "Nested Domain Child"
  end

  test "reading footer shows previous first child and next links but no parent link" do
    parent = Node.create!(
      title: "Parent Node",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    previous_node = Node.create!(
      title: "Previous Sibling",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public"
    )
    current_node = Node.create!(
      title: "Current Sibling",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public"
    )
    next_node = Node.create!(
      title: "Next Sibling",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public"
    )
    child = Node.create!(
      title: "First Child",
      role_assignment: @assignment,
      parent: current_node,
      status: "published",
      visibility: "public"
    )

    get node_url(current_node)

    assert_response :success
    assert_select ".node-public-reading-nav-static"
    assert_select ".node-public-book-prev[href=?]", node_path(previous_node)
    assert_select ".node-public-book-down[href=?]", node_path(child)
    assert_select ".node-public-book-next[href=?]", node_path(next_node)
    assert_select ".node-public-book-up", false
  end

  test "reading footer shows parent node as previous link if there is no previous sibling" do
    parent = Node.create!(
      title: "Parent Node",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    current_node = Node.create!(
      title: "Current Sibling",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public"
    )
    next_node = Node.create!(
      title: "Next Sibling",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public"
    )

    get node_url(current_node)

    assert_response :success
    assert_select ".node-public-reading-nav-static"
    assert_select ".node-public-book-prev[href=?]", node_path(parent)
    assert_select ".node-public-book-next[href=?]", node_path(next_node)
  end

  test "editor actions are visible only to active creator owner" do
    sign_in(@user)

    get node_url(@draft_node)

    assert_response :success
    assert_select ".node-public-creator-menu-toggle"
    assert_select "header a[href=?]", tree_creator_world_role_assignment_node_path(@draft_node.role_assignment, @draft_node), text: "Albero"
    assert_select "header a[href=?]", edit_creator_world_role_assignment_node_path(@draft_node.role_assignment, @draft_node), text: "Modifica"

    delete session_url
    superadmin = User.create!(
      email_address: "node-superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )

    post session_url, params: { email_address: superadmin.email_address, password: "password123" }
    get node_url(@draft_node)

    assert_response :success
    assert_select ".node-public-creator-menu-toggle", false
    assert_select "header a[href=?]", tree_creator_world_role_assignment_node_path(@draft_node.role_assignment, @draft_node), count: 0
    assert_select "header a[href=?]", edit_creator_world_role_assignment_node_path(@draft_node.role_assignment, @draft_node), count: 0
    assert_select ".node-public-status", false
  end

  test "public visitor sees sibling sidebar when siblings exist, and not when they don't" do
    # create sibling
    sibling = Node.create!(
      title: "Published Sibling",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )

    get node_url(@published_node)
    assert_response :success
    assert_select ".node-public-sidebar"
    assert_select ".node-public-sidebar-link", text: "Published Node"
    assert_select ".node-public-sidebar-link", text: "Published Sibling"

    # destroy sibling
    sibling.destroy

    get node_url(@published_node)
    assert_response :success
    assert_select ".node-public-sidebar", false
  end

  test "public visitor sees left sidebar for only child with parent link" do
    parent = Node.create!(
      title: "Parent Section",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    child = Node.create!(
      title: "Only Child",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public"
    )

    get node_url(child)

    assert_response :success
    assert_select ".node-public-sidebar"
    assert_select ".node-public-sidebar-parent-link[href=?]", node_path(parent), text: "Parent Section"
    assert_select ".node-public-sidebar-item.active .node-public-sidebar-link", text: "Only Child"
  end

  test "public sidebar links bridge nodes directly to their target" do
    parent = Node.create!(
      title: "Sidebar Parent",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    current_node = Node.create!(
      title: "Current Section",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public"
    )
    target_node = Node.create!(
      title: "Target Section",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    child_target_node = Node.create!(
      title: "Child Target Section",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    bridge_node = Node.create!(
      title: "Shortcut Section",
      role_assignment: @assignment,
      parent: parent,
      status: "published",
      visibility: "public",
      link_node: target_node
    )
    child_bridge_node = Node.create!(
      title: "Child Shortcut Section",
      role_assignment: @assignment,
      parent: current_node,
      status: "published",
      visibility: "public",
      link_node: child_target_node
    )

    get node_url(current_node)

    assert_response :success
    assert_select ".node-public-sidebar-link[href=?]", node_path(target_node), text: "Shortcut Section"
    assert_select ".node-public-sidebar-link[href=?]", node_path(bridge_node), count: 0
    assert_select ".node-public-sidebar-sublink[href=?]", node_path(child_target_node), text: "Child Shortcut Section"
    assert_select ".node-public-sidebar-sublink[href=?]", node_path(child_bridge_node), count: 0

    get node_url(bridge_node)

    assert_redirected_to node_url(target_node)
  end

  test "public visitor does not see next-section CTA card but sees reading nav on parent node" do
    # create a child
    child = Node.create!(
      title: "First Child Node",
      role_assignment: @assignment,
      parent: @published_node,
      status: "published",
      visibility: "public"
    )

    get node_url(@published_node)
    assert_response :success
    
    # Assert reading navigation is present
    assert_select ".node-public-reading-nav-static"
    
    # Assert next-section CTA card is not present
    assert_select ".node-public-next-section", false

    # Assert TOC sidebar container is present
    assert_select "aside.node-public-toc-sidebar"
    assert_select "aside.node-public-toc-sidebar ul[data-toc-target='list']"

    # Assert left sidebar uses children as section links when there are no siblings
    assert_select ".node-public-sidebar"
    assert_select ".node-public-sidebar-link[href=?]", node_path(child), text: "First Child Node"

    # destroy child
    child.destroy

    get node_url(@published_node)
    assert_response :success
    assert_select ".node-public-next-section", false
    assert_select ".node-public-sidebar", false
  end

  test "markdown headings render stable ids for right toc" do
    @published_node.content.update!(
      body_md: <<~MD
        # Introduzione

        Testo introduttivo.

        ## Dettagli Importanti

        ### Sotto Sezione

        ## Dettagli Importanti
      MD
    )

    get node_url(@published_node)

    assert_response :success
    assert_select ".node-public-content h1#introduzione", "Introduzione"
    assert_select ".node-public-content h2#dettagli-importanti", "Dettagli Importanti"
    assert_select ".node-public-content h3#sotto-sezione", "Sotto Sezione"
    assert_select ".node-public-content h2#dettagli-importanti-2", "Dettagli Importanti"
    assert_select "aside.node-public-toc-sidebar[data-controller='toc']"
    assert_select "aside.node-public-toc-sidebar ul[data-toc-target='list']"
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
