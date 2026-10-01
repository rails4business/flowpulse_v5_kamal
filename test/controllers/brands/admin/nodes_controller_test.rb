require "test_helper"

class Brands::Admin::NodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "brand-nodes-owner@example.com", password: "password123", password_confirmation: "password123")
    profile = @owner.create_profile!(display_name: "Brand Nodes Owner")
    role = RoleAssignment.create!(profile: profile, role: :creator_of_worlds)
    @brand = Node.create!(role_assignment: role, title: "PosturaCorretta", slug: "posturacorretta", status: "published")
    Domain.create!(hostname: "brand-nodes.test", node: @brand, role_assignment: role, active: true)
    @project = Node.create!(parent: @brand, title: "Primo progetto", status: "draft")
  end

  test "brand node map is private" do
    get brand_admin_nodes_url(@brand.slug)

    assert_redirected_to new_session_url(return_to: brand_admin_nodes_path(@brand.slug))
  end

  test "brand owner sees the real node tree in the dedicated administration" do
    sign_in(@owner)

    get brand_admin_nodes_url(@brand.slug)

    assert_response :success
    assert_select "h1", "PosturaCorretta · Nodi"
    assert_select "button[data-node-dialog-open]", count: 0
    assert_select "button[data-node-add-parent='#{@brand.id}']", text: "+ sotto"
    assert_select "[role='tree'] a[href='#{brand_admin_node_path(@brand.slug, @project)}']", text: "Primo progetto"
    assert_select "button[data-node-add-parent='#{@project.id}']", text: "+ sotto"
    assert_select "#brand-node-map-data", count: 0
    assert_select "body.brand-admin-body"
    assert_select "a", text: "Admin", count: 0
    assert_select ".brand-admin-nav a[aria-current='page']", text: "Nodi"
    assert_select "aside[aria-label='Istruzioni superadmin per lo snapshot YAML']", count: 0
  end

  test "superadmin opens the visual schema in a separate tab" do
    sign_in(@owner)

    get brand_admin_nodes_url(@brand.slug, view: "schema")

    assert_response :success
    assert_select ".brand-admin-nav a[aria-current='page']", text: "Schema"
    assert_select "#brand-node-map-svg"
    assert_select "#brand-node-map-data", text: /Primo progetto/
    assert_select "#brand-node-map-data", text: /Iscrizione al percorso online/, count: 0
  end

  test "brand owner creates a real child node and records its birth" do
    sign_in(@owner)

    assert_difference -> { Node.count }, 1 do
      assert_difference -> { NodeEvent.count }, 1 do
        post brand_admin_nodes_url(@brand.slug), params: { node: { title: "Corso online", parent_id: @project.id, description: "Primo passo reale", status: "draft" } }
      end
    end

    node = Node.order(:created_at).last
    assert_equal @project, node.parent
    assert_equal @brand.role_assignment, node.role_assignment
    assert_equal ["created", @owner], [node.node_events.last.kind, node.node_events.last.performed_by_user]
    assert_redirected_to brand_admin_node_url(@brand.slug, node)
  end

  test "opening a node shows its processes" do
    process_record = NodeProcess.create!(node: @project, created_by_user: @owner, title: "Pubblicazione settimanale", status: "active")
    sign_in(@owner)

    get brand_admin_node_url(@brand.slug, @project)

    assert_response :success
    assert_select "h1", "Primo progetto"
    assert_select "[data-node-identity-show] button[data-node-identity-edit]", text: "Modifica"
    assert_select "form[data-node-identity-form][hidden] textarea[name='node[description]']"
    assert_select "h2", "Processi"
    assert_select "h3", process_record.title
    assert_select "a[href='#{brand_admin_node_process_path(@brand.slug, @project, process_record)}']"
    assert_select "button", text: /Processo/
    assert_select "form[action='#{processes_brand_admin_node_path(@brand.slug, @project)}'] input[name='node_process[title]']"
    assert_select "a[href='#{admin_brand_path(@project, tab: "processes")}']", count: 0
    assert_select "h2", "Vita del progetto"
    assert_select "form[action='#{brand_admin_node_path(@brand.slug, @project)}'] input[data-bridge-search][list='node_bridge_options']"
    assert_select "form[action='#{brand_admin_node_path(@brand.slug, @project)}'] input[type='hidden'][name='node[link_node_id]']"
    assert_select "h2", text: "Struttura del nodo", count: 0
    assert_select "a[href='#{brand_admin_node_path(@brand.slug, @project)}'][data-turbo-method='delete']", text: "Elimina nodo"
  end

  test "owner opens a process schema with its experiences" do
    process_record = NodeProcess.create!(node: @project, created_by_user: @owner, title: "Pubblicazione settimanale", status: "active")
    DataExperience.create!(node_process: process_record, created_by_user: @owner, title: "Primo capitolo")
    sign_in(@owner)

    get brand_admin_node_process_url(@brand.slug, @project, process_record)

    assert_response :success
    assert_select "h1", process_record.title
    assert_select "h2", "Dal processo al lavoro reale"
    assert_select "div", text: /NodeProcess/
    assert_select "h2", "DataExperience"
    assert_select "h3", "Primo capitolo"
    assert_select "a[href='#{impegno_experience_path(DataExperience.last)}']", text: /Primo capitolo/
    assert_select "button", text: "Modifica"
    assert_select "form[action='#{brand_admin_node_process_path(@brand.slug, @project, process_record)}'] input[name='node_process[title]']"
    assert_select "button", text: /DataExperience/
    assert_select "p", text: /Appunto 1/
    assert_select "p", text: /Appunto 2/
  end

  test "owner updates a process from its show" do
    process_record = NodeProcess.create!(node: @project, created_by_user: @owner, title: "Processo iniziale", status: "draft")
    sign_in(@owner)

    patch brand_admin_node_process_url(@brand.slug, @project, process_record), params: {
      node_process: { title: "Processo aggiornato", slug: "processo-aggiornato", description: "Nuova descrizione", status: "active" }
    }

    assert_redirected_to brand_admin_node_process_url(@brand.slug, @project, process_record)
    assert_equal ["Processo aggiornato", "processo-aggiornato", "active"], process_record.reload.values_at("title", "slug", "status")
  end

  test "owner adds a DataExperience from the process show" do
    process_record = NodeProcess.create!(node: @project, created_by_user: @owner, title: "Pubblicazione settimanale", status: "active")
    sign_in(@owner)

    assert_difference -> { DataExperience.count }, 1 do
      post experiences_brand_admin_node_process_url(@brand.slug, @project, process_record), params: {
        data_experience: { title: "Capitolo della settimana", description: "Prima applicazione concreta" }
      }
    end

    experience = DataExperience.last
    assert_equal process_record, experience.node_process
    assert_equal @owner, experience.created_by_user
    assert_redirected_to brand_admin_node_process_url(@brand.slug, @project, process_record, anchor: "process-experiences")
  end


  test "owner creates a process directly from the node" do
    sign_in(@owner)

    assert_difference -> { NodeProcess.count }, 1 do
      post processes_brand_admin_node_url(@brand.slug, @project), params: {
        node_process: { title: "Pubblicare un capitolo", description: "Ciclo editoriale settimanale", status: "active" }
      }
    end

    process_record = NodeProcess.last
    assert_equal @project, process_record.node
    assert_equal "pubblicare-un-capitolo", process_record.slug
    assert_redirected_to brand_admin_node_url(@brand.slug, @project, anchor: "node-processes")
  end

  test "superadmin creates a bridge node" do
    target = Node.create!(role_assignment: @brand.role_assignment, title: "Progetto collegato", slug: "progetto-collegato")
    sign_in(@owner)

    assert_difference -> { Node.count }, 1 do
      post brand_admin_nodes_url(@brand.slug), params: { node: { title: "Ponte al progetto", parent_id: @brand.id, link_node_id: target.id, status: "draft" } }
    end

    bridge = Node.order(:created_at).last
    assert_equal target, bridge.link_node
    assert bridge.bridge_node?
  end

  test "superadmin updates and deletes a leaf node" do
    sign_in(@owner)

    patch brand_admin_node_url(@brand.slug, @project), params: { node: { title: "Progetto aggiornato", parent_id: @brand.id, status: "published" } }

    assert_redirected_to brand_admin_node_url(@brand.slug, @project)
    @project.reload
    assert_equal ["Progetto aggiornato", "published"], [@project.title, @project.status]

    assert_difference -> { Node.count }, -1 do
      delete brand_admin_node_url(@brand.slug, @project)
    end
    assert_redirected_to brand_admin_nodes_url(@brand.slug)
  end

  test "superadmin cannot delete a node that still has children" do
    Node.create!(parent: @project, title: "Figlio")
    sign_in(@owner)

    assert_no_difference -> { Node.count } do
      delete brand_admin_node_url(@brand.slug, @project)
    end

    assert_redirected_to brand_admin_node_url(@brand.slug, @project)
    assert_equal "Prima di eliminare il nodo, ricolloca o elimina i nodi figli.", flash[:alert]
  end

  test "a node with children does not show the bridge selector" do
    Node.create!(parent: @project, title: "Figlio")
    sign_in(@owner)

    get brand_admin_node_url(@brand.slug, @project)

    assert_response :success
    assert_select "[data-bridge-unavailable]", text: /Nodo ponte non disponibile/
    assert_select "input[data-bridge-search]", count: 0
    assert_select "input[name='node[link_node_id]']", count: 0
  end

  test "brand owner advances a node through its lifecycle" do
    sign_in(@owner)

    assert_difference -> { NodeEvent.count }, 1 do
      patch lifecycle_brand_admin_node_url(@brand.slug, @project), params: { event: "started", note: "Prima versione" }
    end

    assert_redirected_to brand_admin_node_url(@brand.slug, @project)
    assert_equal "active", @project.reload.cell_status
    assert_equal @owner, @project.node_events.last.performed_by_user

    get brand_admin_node_url(@brand.slug, @project)
    assert_select "[data-cell-status-badge='active']", text: /In corso/
    assert_select "[data-node-event='started']", text: /▶.*Avviato/
  end

  test "update and fix are recorded without changing the project state" do
    @project.node_events.create!(kind: "started", performed_by_user: @owner)
    sign_in(@owner)

    assert_difference -> { NodeEvent.count }, 2 do
      patch lifecycle_brand_admin_node_url(@brand.slug, @project), params: { event: "updated", node_event: { title: "Aggiornato accesso", body_md: "## Modifica\n\nAccesso collegato." } }
      patch lifecycle_brand_admin_node_url(@brand.slug, @project), params: { event: "fixed", node_event: { title: "Corretto avanzamento", development_entry_slug: "posturacorretta-programma-lezioni-studente-insegnante" } }
    end

    assert_equal "active", @project.reload.cell_status
    get brand_admin_node_url(@brand.slug, @project)
    assert_select "[data-node-event='updated']", text: /Aggiornato/
    assert_select "[data-node-event='fixed']", text: /Corretto/
    assert_select "[data-node-event='fixed'] a", text: /Scheda/
    event = @project.node_events.find_by!(kind: "updated")
    assert_match(/\A[0-9a-f-]{36}\z/, event.public_id)
    assert_select "ol.list-none a[href='#{brand_admin_node_event_path(@brand.slug, @project, event.public_id)}']", text: /Aggiornato accesso/

    get brand_admin_node_event_url(@brand.slug, @project, event.public_id)
    assert_response :success
    assert_select "h1", "Aggiornato accesso"
    assert_select ".editorial-rich-text h2", "Modifica"
  end

  test "an update can use only Markdown without a separate title" do
    sign_in(@owner)

    assert_difference -> { NodeEvent.count }, 1 do
      patch lifecycle_brand_admin_node_url(@brand.slug, @project), params: { event: "updated", node_event: { body_md: "# Aggiornamento dal Markdown\n\nDettagli." } }
    end

    event = @project.node_events.order(:id).last
    assert_nil event.title
    get brand_admin_node_event_url(@brand.slug, @project, event.public_id)
    assert_response :success
    assert_select ".editorial-rich-text h1", "Aggiornamento dal Markdown"
  end

  test "owner can complete the automatically created event with Markdown and a future development slug" do
    created_event = @project.node_events.create!(kind: "created", performed_by_user: @owner)
    sign_in(@owner)

    get brand_admin_node_event_url(@brand.slug, @project, created_event.public_id)

    assert_response :success
    assert_select "button[data-node-event-edit]", text: "Modifica"
    assert_select "form[data-node-event-form][hidden]"
    assert_select "input[name='node_event[development_entry_slug]'][list='event-development-entry-slugs']"
    assert_select "textarea[name='node_event[body_md]']"

    patch brand_admin_node_event_url(@brand.slug, @project, created_event.public_id), params: {
      node_event: {
        title: "Creato percorso online",
        development_entry_slug: "posturacorretta-percorso-online",
        body_md: "## Primo piano\n\nPartire dalle iscrizioni."
      }
    }

    assert_redirected_to brand_admin_node_event_url(@brand.slug, @project, created_event.public_id)
    created_event.reload
    assert_equal "Creato percorso online", created_event.title
    assert_equal "posturacorretta-percorso-online", created_event.development_entry_slug

    follow_redirect!
    assert_select "h1", "Creato percorso online"
    assert_select ".editorial-rich-text h2", "Primo piano"
    assert_select "p", text: /Markdown atteso/
  end

  test "the Brand node shows its linked development Markdown" do
    event = @brand.node_events.create!(kind: "updated", title: "Aggiornata struttura", performed_by_user: @owner)
    sign_in(@owner)

    get brand_admin_node_url(@brand.slug, @brand)

    assert_response :success
    assert_select "#lifecycle-title", "Aggiornamenti del Brand"
    assert_select "button[data-event-kind='updated']", text: /Update/
    assert_select "button[data-event-kind='fixed']", text: /Fix/
    assert_select "a[href='#{brand_admin_node_event_path(@brand.slug, @brand, event.public_id)}']", text: "Aggiornata struttura"
    assert_select "#node-development-title", "Schede nate dai NodeEvent"
    assert_select "a[href='#{brand_admin_development_entry_path(@brand.slug, "posturacorretta-programma-lezioni-studente-insegnante")}']"
  end

  test "unrelated user cannot administer the brand" do
    outsider = User.create!(email_address: "brand-outsider@example.com", password: "password123", password_confirmation: "password123")
    outsider.create_profile!(display_name: "Outsider")
    sign_in(outsider)

    get brand_admin_nodes_url(@brand.slug)

    assert_response :forbidden
  end

  test "a delegated brand administrator can access the panel" do
    delegate = User.create!(email_address: "brand-delegate@example.com", password: "password123", password_confirmation: "password123")
    delegate_profile = delegate.create_profile!(display_name: "Brand Delegate")
    RoleAssignment.create!(profile: delegate_profile, role: :admin, context: @brand, parent: @brand.role_assignment)
    sign_in(delegate)

    get brand_admin_nodes_url(@brand.slug)

    assert_response :success
  end

  test "superadmin can enter as support without becoming the brand owner" do
    support = User.create!(email_address: "brand-support@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
    support.create_profile!(display_name: "Support")
    sign_in(support)

    get brand_admin_nodes_url(@brand.slug)

    assert_response :success
    assert_select ".brand-admin-support", text: /Assistenza superadmin/
    assert_select "aside[aria-label='Istruzioni superadmin per lo snapshot YAML']", text: /brand_nodes:export/
  end

  private

    def sign_in(user)
      post session_url, params: { email_address: user.email_address, password: "password123" }
    end
end
