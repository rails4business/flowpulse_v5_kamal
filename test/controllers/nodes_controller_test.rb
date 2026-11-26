require "test_helper"

class NodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "public-node-creator@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @user.create_profile!(display_name: "Public Node Creator")
    @assignment = RoleAssignment.create!(profile: @user.profile, role: :ideatore)
    @user.update!(active_role: :ideatore, current_role_assignment: @assignment)
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

  test "PosturaCorretta public sections use branded URLs and dedicated landings" do
    brand = Node.create!(
      title: "PosturaCorretta",
      slug: "posturacorretta",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    sections = {
      "partecipa-posturacorretta" => ["Partecipa", posturacorretta_partecipa_url],
      "servizi-posturacorretta" => ["Servizi", posturacorretta_servizi_url],
      "about-posturacorretta" => ["About", posturacorretta_about_url]
    }
    nodes = sections.to_h do |slug, (title, _url)|
      node = Node.create!(
        title: title,
        slug: slug,
        role_assignment: @assignment,
        parent: brand,
        status: "published",
        visibility: "public"
      )
      node.content.update!(body_md: "## Contenuto #{title}")
      [slug, node]
    end
    Node.create!(
      title: "Incontri settimanali",
      role_assignment: @assignment,
      parent: nodes.fetch("partecipa-posturacorretta"),
      status: "published",
      visibility: "public"
    )
    Domain.create!(
      hostname: "posturacorretta-public-sections.test",
      node: brand,
      role_assignment: @assignment,
      path_slug: "posturacorretta",
      home_mode: "node",
      locale: "it"
    )

    sections.each do |slug, (title, public_url)|
      get public_url

      assert_response :success
      assert_select "body.pc-posturacorretta-site", count: 1
      assert_select ".node-public-page.node-public-landing", count: 1
      assert_select "h1", minimum: 1
      assert_select ".node-public-breadcrumb", count: 0
      assert_select ".node-public-sidebar", count: 0
      assert_select ".node-public-toc-sidebar", count: 0

      get node_url(nodes.fetch(slug))
      assert_redirected_to public_url
      assert_response :moved_permanently
    end

    get posturacorretta_partecipa_url
    assert_select "h2", text: "Incontri settimanali"

    get posturacorretta_about_url
    assert_select ".pc-faq-page h1", text: "Hai domande?"
    assert_select ".pc-faq-list details", count: 5
    assert_select ".pc-faq-list details[open]", count: 1
  end

  test "PosturaCorretta Consapevolezza renders its three-section landing" do
    skip "In pausa (CI #249, 23/11/2026): da riallineare al nuovo lavoro su PosturaCorretta"
    brand = Node.create!(
      title: "PosturaCorretta",
      slug: "posturacorretta",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    import_posturacorretta_contents
    node = Node.create!(
      title: "Educazione 2 · Consapevolezza con le metodiche posturali",
      slug: "apprendimento-2-connessione",
      role_assignment: @assignment,
      parent: brand,
      status: "published",
      visibility: "public"
    )
    Domain.create!(
      hostname: "posturacorretta-consapevolezza.test",
      node: brand,
      role_assignment: @assignment,
      path_slug: "posturacorretta",
      home_mode: "node",
      locale: "it"
    )

    get posturacorretta_consapevolezza_url

    assert_response :success
    assert_select ".node-public-page.node-public-landing", count: 1
    assert_select "h1", text: "Attività e percorsi"
    assert_select "nav[aria-label='Sezioni di Consapevolezza'] a", count: 3
    assert_select "a[aria-current='page']", text: "Corso"
    assert_select "h2", text: "Postura e consapevolezza"
    assert_select "span", text: "In preparazione"

    get posturacorretta_consapevolezza_url(tab: "metodiche")

    assert_response :success
    assert_select "a[aria-current='page']", text: "Metodiche posturali"
    assert_select "a[href='#{posturacorretta_metodica_path('feldenkrais')}']", minimum: 1

    get posturacorretta_consapevolezza_url(tab: "percorsi")

    assert_response :success
    assert_select "a[aria-current='page']", text: "Percorsi mirati"
    assert_select "nav[aria-label='Tipi di percorsi mirati'] a", count: 3
    assert_select "nav[aria-label='Tipi di percorsi mirati'] a[aria-selected='true']", text: "Persone e fasi della vita"

    get posturacorretta_url(area: "connessione", tab: "corpo")
    assert_response :success
    assert_select "nav[aria-label='Percorso PosturaCorretta']", text: /Home.*Connessione/
    assert_select "nav[aria-label='Sezioni di Connessione'] a[aria-current='page']", text: "Il corpo"
    assert_select "a[href='#{book_path('il-corpo-un-mondo-da-scoprire')}']", text: /Il corpo, un mondo da scoprire/

    get posturacorretta_url(area: "connessione", tab: "risorse")
    assert_response :success
    assert_select "nav[aria-label='Sezioni di Connessione'] a[aria-current='page']", text: "Le tue risorse"
    assert_select "h2", text: /Le tue risorse|Ascolta gli aspetti vitali/
    assert_select "[role='tabpanel']", text: /Percorsi pensati per età/

    get posturacorretta_consapevolezza_url(tab: "percorsi", percorso: "attivita")

    assert_response :success
    assert_select "nav[aria-label='Tipi di percorsi mirati'] a[aria-selected='true']", text: "Attività e contesti"
    assert_select "[role='tabpanel']", text: /Percorsi collegati al lavoro/

    get node_url(node, tab: "percorsi")

    assert_redirected_to posturacorretta_consapevolezza_url(tab: "percorsi")
    assert_response :moved_permanently
  end

  test "PosturaCorretta Connessione renders Corpo and Risorse" do
    brand = Node.create!(
      title: "PosturaCorretta",
      slug: "posturacorretta",
      role_assignment: @assignment,
      status: "published",
      visibility: "public"
    )
    import_posturacorretta_contents
    node = Node.create!(
      title: "Educazione 3 · Connessione dalla PosturaCorretta al Giardino del Corpo",
      slug: "dalla-posturacorretta-al-giardino-del-corpo",
      role_assignment: @assignment,
      parent: brand,
      status: "published",
      visibility: "public"
    )
    Domain.create!(
      hostname: "posturacorretta-connessione.test",
      node: brand,
      role_assignment: @assignment,
      path_slug: "posturacorretta",
      home_mode: "node",
      locale: "it"
    )

    get posturacorretta_connessione_url

    assert_response :success
    assert_select ".node-public-page.node-public-landing", count: 1
    assert_select "nav[aria-label='Sezioni di Connessione'] a", count: 2
    assert_select "a[aria-current='page']", text: "Il corpo"
    assert_select "h2", text: "Dalla PosturaCorretta al Giardino del Corpo"
    assert_select "a[href='#{posturacorretta_course_path('corpo-come-un-giardino')}']", text: /Inizia il corso/
    assert_select "a[href='#{book_path('il-corpo-un-mondo-da-scoprire')}']", text: /Il corpo, un mondo da scoprire/

    get posturacorretta_connessione_url(tab: "risorse")

    assert_response :success
    assert_select "a[aria-current='page']", text: "Le tue risorse"
    assert_select "h2", text: "Le tue risorse"
    assert_select "span", text: "In preparazione"

    get posturacorretta_url(parte: "corpo")
    assert_redirected_to posturacorretta_connessione_url(tab: "corpo")
    assert_response :moved_permanently

    get posturacorretta_url(parte: "risorse")
    assert_redirected_to posturacorretta_connessione_url(tab: "risorse")
    assert_response :moved_permanently

    get node_url(node, tab: "risorse")

    assert_redirected_to posturacorretta_connessione_url(tab: "risorse")
    assert_response :moved_permanently
  end

  test "local brand path renders the Node Show assigned to its domain" do
    Domain.create!(
      hostname: "posturacorretta.org",
      node: @published_node,
      role_assignment: @assignment,
      path_slug: "posturacorretta",
      home_mode: "node",
      locale: "it"
    )

    get posturacorretta_url

    assert_response :success
    assert_includes response.body, "Published Node"
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "PosturaCorretta home presents three choices and Expression keeps the program tabs" do
    skip "In pausa (CI #249, 23/11/2026): da riallineare al nuovo lavoro su PosturaCorretta"
    brand = Node.create!(
      title: "PosturaCorretta",
      slug: "posturacorretta",
      role_assignment: @assignment,
      status: "published",
      visibility: "public",
      navigation: {
        "items" => [
          {
            "key" => "percorso",
            "label" => "Percorso",
            "group" => true,
            "children" => [
              { "key" => "espressione", "label" => "Espressione", "path" => "/posturacorretta/espressione" }
            ]
          }
        ]
      }
    )
    import_posturacorretta_contents
    Node.create!(
      title: "Child course",
      role_assignment: @assignment,
      parent: brand,
      status: "published",
      visibility: "public"
    )
    Domain.create!(
      hostname: "posturacorretta-native.test",
      node: brand,
      role_assignment: @assignment,
      path_slug: "posturacorretta",
      home_mode: "node",
      locale: "it"
    )

    get posturacorretta_url

    assert_response :success
    assert_select ".pc-intro-sheet__hero h1", text: "Non è solo stare ben dritti con la schiena."
    assert_select ".pc-index-cabinet__tabs", count: 0
    assert_select "nav[aria-label='Percorso PosturaCorretta']", count: 0
    assert_select "section[aria-label='Aree del percorso PosturaCorretta'] a[href='#{posturacorretta_path(area: "espressione")}']", text: /Vai/
    assert_select "section[aria-label='Aree del percorso PosturaCorretta'] a[href='#{posturacorretta_path(area: "consapevolezza")}']", text: /Vai/
    assert_select "section[aria-label='Aree del percorso PosturaCorretta'] a[href='#{posturacorretta_path(area: "connessione")}']", text: /Vai/
    assert_select ".pc-landing-home", count: 1
    assert_select ".pc-expression-tabs", count: 0
    assert_select ".pc-intro-sheet__hero img[src*='posturacorretta_home.png']", count: 1
    assert_select ".pc-intro-sheet__principles", count: 0
    assert_select "a[href='#{posturacorretta_course_chapter_path(corso: "inizia-con-posturacorretta", capitolo: "come-si-affronta-il-programma")}']", text: "Scopri di più"
    assert_select ".pc-intro-sheet__program .pc-intro-program-list__row.is-course", count: 3
    assert_select ".pc-intro-sheet__program .pc-intro-program-list__row.is-lesson", count: 3
    assert_select ".pc-sheet__print", text: "Scarica o stampa Inizia il programma"

    get posturacorretta_url(area: "espressione")
    assert_response :success
    assert_select "nav[aria-label='Percorso PosturaCorretta']", text: /Home.*Percorso educativo/
    assert_select "nav[aria-label='Sezioni del percorso educativo'] > a", count: 4
    assert_select "nav[aria-label='Sezioni del percorso educativo'] > a[aria-current='page']", text: "Recupero e terapie manuali"
    assert_select ".pc-program-sheet__intro h1", text: "Recupero e terapie manuali"
    assert_select "a[href='#{posturacorretta_path(area: "espressione", parte: "movimento-allenamento")}']", text: /Continua.*Movimento e allenamento/
    assert_select "a[href='#{posturacorretta_path}']", text: /Indietro.*Home/

    get posturacorretta_url(area: "intro")
    assert_redirected_to posturacorretta_url
    assert_response :moved_permanently

    get posturacorretta_url(area: "espressione", parte: "mente")
    assert_response :success
    assert_select "nav[aria-label='Sezioni del percorso educativo'] > a[aria-current='page']", text: "Mente e aspetti emotivi e mentali"
    assert_select ".pc-program-placeholder h1", text: "Mente e aspetti emotivi e mentali"
    assert_select ".pc-journey-footer__progress", text: "4 / 7"

    get posturacorretta_url(area: "consapevolezza")
    assert_response :success
    assert_select "nav[aria-label='Percorso PosturaCorretta']", text: /Home.*Consapevolezza/
    assert_select "nav[aria-label='Sezioni di Consapevolezza'] a[aria-current='page']", text: "Corso"
    assert_select "p", text: "Corso online"
    assert_select "span", text: "In preparazione"

    get posturacorretta_url(area: "consapevolezza", tab: "metodiche")
    assert_response :success
    assert_select "nav[aria-label='Sezioni di Consapevolezza'] a[aria-current='page']", text: "Metodiche posturali"
    assert_select "a[href='#{posturacorretta_metodica_path('gds')}']", minimum: 1

    get posturacorretta_url(area: "consapevolezza", tab: "percorsi")
    assert_response :success
    assert_select "nav[aria-label='Sezioni di Consapevolezza'] a[aria-current='page']", text: "Percorsi mirati"
    assert_select "nav[aria-label='Tipi di percorsi mirati'] a", count: 3
    assert_select "nav[aria-label='Tipi di percorsi mirati'] a[aria-selected='true']", text: "Persone e fasi della vita"

    get posturacorretta_espressione_url

    assert_response :success
    assert_select ".pc-landing-home", count: 1
    assert_select "nav[aria-label='Percorso PosturaCorretta']", text: /Home.*Percorso educativo/
    assert_select ".pc-expression-tabs .pc-expression-tab", count: 4
    assert_select ".pc-expression-tab.is-selected", text: "Recupero e terapie manuali"
    assert_select ".pc-expression-tab", text: "Il corpo, un mondo da scoprire", count: 0
    assert_select ".pc-expression-tab", text: "Gestione risorse e progetto", count: 0
    assert_select ".pc-program-sheet__intro h1", text: "Recupero e terapie manuali"
    assert_select "#lezioni-e-percorsi", count: 0
    assert_select ".pc-listino__note", count: 0
    assert_select ".pc-home-tabs", count: 0

    get posturacorretta_espressione_url(parte: "recupero-massaggio")

    assert_response :success
    assert_select ".pc-expression-tab.is-selected", text: "Recupero e terapie manuali"
    assert_select ".pc-program-sheet__intro h1", text: "Recupero e terapie manuali"
    assert_select ".pc-program-sheet__intro", text: /Il massaggio è una delle pratiche/, count: 0
    assert_select ".pc-sheet__print", text: "Scarica o stampa Recupero e terapie manuali"

    get posturacorretta_espressione_url(parte: "intro")
    assert_redirected_to posturacorretta_url
    assert_response :moved_permanently

    get posturacorretta_url(parte: "recupero-massaggio")
    assert_redirected_to posturacorretta_espressione_url(parte: "recupero-massaggio")
    assert_response :moved_permanently

    get posturacorretta_postura_recupero_url(tappa: "la-prima-settimana-con-posturacorretta", tab: "lezioni")

    assert_response :success
    assert_select "iframe", count: 0
    assert_select ".pc-landing-home", count: 0
    assert_select ".pc-home-tabs a", minimum: 2
    assert_select ".pc-home-tab", text: "Percorso online"
    assert_select ".pc-home-tab", text: "Lezione"
    assert_select ".pc-home-journey__breadcrumb", text: /Prima settimana/
    assert_select ".pc-home-journey__aside .pc-program-stepper", count: 1
    assert_select ".pc-home-journey__aside", text: /Inizia con PosturaCorretta/
    assert_select ".pc-home-journey__aside .pc-program-stepper__step--course", count: 3
    assert_select ".pc-home-journey__aside .pc-program-stepper__step--lesson", count: 3
    assert_select ".pc-home-journey__aside a[aria-label='Apri il corso Inizia il percorso'][href='#{posturacorretta_course_path(corso: "introduzione-percorso-integrato-posturacorretta")}']", count: 1
    assert_select ".pc-home-panel--lezioni", text: /Lezione 1/
    assert_select ".pc-program-stepper__step[href^='#{posturacorretta_postura_recupero_path}']", minimum: 1
    assert_select ".node-public-reading-nav-static", count: 0

    get posturacorretta_postura_recupero_url(tab: "percorso")
    assert_redirected_to posturacorretta_url
    assert_response :moved_permanently
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

  test "journey online view renders the reusable lesson data and chapter template" do
    import_posturacorretta_contents
    brand = Node.find_by!(slug: "posturacorretta")
    brand.update!(status: "published", visibility: "public")
    Domain.create!(
      hostname: "posturacorretta-lesson-show.test", node: brand, role_assignment: brand.role_assignment,
      path_slug: "posturacorretta", home_mode: "node", locale: "it"
    ) unless Domain.exists?(hostname: "posturacorretta-lesson-show.test")
    lesson_node = Node.find_by!(slug: "introduzione-al-percorso-integrato")
    lesson_node.update!(title: "Lezione · Inizia il percorso", description: "Presentazione della lezione", status: "published")

    get posturacorretta_postura_recupero_url(tappa: lesson_node.slug, tab: "online")

    assert_response :success
    assert_select "section[aria-labelledby='journey-lesson-title']", count: 1 do
      assert_select "h2", text: "Inizia il percorso"
      assert_select ".pc-lesson-session-row", text: /Data e ora.*Centro.*Insegnante.*Firma/m
      assert_select ".node-public-content", count: 0
      assert_select "iframe", count: 0
    end
    assert_select ".pc-intro-program-list", count: 0
    assert_select "ol", text: /Percorso Integrato · Tre percorsi complementari/
  end

  test "journey course slugs redirect to the canonical course show while lessons stay in the journey" do
    import_posturacorretta_contents
    brand = Node.find_by!(slug: "posturacorretta")
    brand.update!(status: "published", visibility: "public")
    Domain.create!(
      hostname: "posturacorretta-course-redirect.test", node: brand, role_assignment: brand.role_assignment,
      path_slug: "posturacorretta", home_mode: "node", locale: "it"
    ) unless Domain.find_for_path_slug("posturacorretta")
    line = Node.find_or_create_by!(slug: "linea-course-redirect-test") do |node|
      node.title = "Linea test"
      node.view_type = "course_line"
      node.parent = brand
      node.role_assignment = brand.role_assignment
    end
    course = Node.find_or_create_by!(slug: "corso-introduzione-al-percorso-integrato") do |node|
      node.title = "Inizia il percorso"
      node.view_type = "course"
      node.parent = line
      node.role_assignment = brand.role_assignment
    end
    content = Content.find_by!(key: "introduzione-percorso-integrato-posturacorretta")
    course.outgoing_content_links.find_or_create_by!(target_content: content, kind: "show")
    course.update!(show_content: content)

    get posturacorretta_postura_recupero_url(tappa: course.slug, tab: "online")

    assert_redirected_to posturacorretta_course_url(corso: content.slug)
    assert_response :moved_permanently
  end

  test "traveler with ancestor brand access can view a subscription node" do
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
    BrandAccess.create!(profile: traveler.profile, source_domain: domain)
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

    BrandAccess.create!(profile: traveler.profile, source_domain: domain)
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
      target_action: "rails4b",
      locale: "it"
    )

    get node_url(@published_node)

    assert_redirected_to rails4b_path
  end

  test "traveler without access sees invitation request on domain node" do
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
    assert_select "header a[href=?]", new_brand_access_request_path, text: "Richiedi accesso"
    assert_select "header details summary.rounded-full", text: /N/
    assert_select "header details a[href=?]", dashboard_path, text: "Dashboard"
    assert_select ".node-public-breadcrumb", count: 0
    assert_includes response.body, "Richiedi accesso"
  end

  test "public visitor sees invitation request on domain node" do
    Domain.create!(
      hostname: "anonymous-subscribe.example",
      node: @published_node,
      role_assignment: @assignment,
      locale: "it"
    )

    get node_url(@published_node)

    assert_response :success
    assert_select "header a[href=?]", new_brand_access_request_path, text: "Richiedi accesso"
  end

  test "traveler sees invitation request on nodes inside a navigation domain" do
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
    assert_select "header a[href=?]", new_brand_access_request_path, text: "Richiedi accesso"
    assert_operator response.body.index("Richiedi accesso"), :<, response.body.index("node-public-breadcrumb")
  end

  test "creator can preview own draft node" do
    sign_in(@user)

    get node_url(@draft_node)

    assert_response :success
    assert_includes response.body, "Draft Node"
    assert_not_includes response.body, "Anteprima privata"
    assert_select ".node-public-status", false
    assert_select ".node-public-creator-menu-toggle", count: 1
    assert_includes response.body, dashboard_path
    assert_no_match admin_dashboard_path, response.body
  end

  test "only superadmin can open the short development edit route" do
    superadmin = User.create!(
      email_address: "catalog-superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    superadmin.create_profile!(display_name: "Catalog Superadmin")
    sign_in(superadmin)

    get edit_node_url(@draft_node, return_to: "/flowpulse/rete/globale")

    assert_redirected_to edit_creator_world_role_assignment_node_url(
      @draft_node.role_assignment,
      @draft_node,
      return_to: "/flowpulse/rete/globale"
    )
    follow_redirect!
    assert_response :success
    assert_select "textarea[name='node[navigation_input]']"
    assert_select "a[href='/flowpulse/rete/globale']", text: /Torna alla rete/

    delete session_url
    sign_in(@user)
    get edit_node_url(@draft_node)
    assert_redirected_to node_url(@draft_node)
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
    domain_root.update!(navigation: {
      "items" => [
        { "slug" => child.slug, "label" => "Domain Child" },
        { "slug" => sibling.slug, "label" => "Domain Sibling" }
      ]
    })

    host! "www.bounded.example"
    get node_url(child)

    assert_response :success
    assert_select "aside#bookAside", false
    assert_select "link[rel='icon'][href='https://cdn.example.com/bounded-square.png']"
    assert_select "link[rel='apple-touch-icon'][href='https://cdn.example.com/bounded-square.png']"
    assert_select ".node-public-breadcrumb-current", "Domain Child"
    assert_select ".node-public-breadcrumb img", count: 0
    assert_select "header nav[aria-label='Navigazione principale']", count: 1
    assert_select "header nav[aria-label='Navigazione principale'] > a[href=?][aria-label='bounded.example · Home']", root_path
    assert_select "header nav[aria-label='Navigazione principale'] a[href=?]", node_path(child), text: "Domain Child"
    assert_select "header nav[aria-label='Navigazione principale'] a[href=?]", node_path(sibling), text: "Domain Sibling"
    assert_select "header nav[aria-label='Navigazione principale'] a[aria-current='page'][href=?]", node_path(child), text: "Domain Child"
    assert_select "header nav[aria-label='Navigazione principale'] a[aria-current='page'][href=?]", node_path(sibling), count: 0
    assert_select ".node-public-reading-nav-static"
    assert_no_match "www.bounded.example", css_select(".node-public-breadcrumb").to_s
    assert_no_match "Top Root", response.body
    assert_includes response.body, "bounded.example"
    assert_includes response.body, "Domain Sibling"
    assert_no_match "Indice del Libro", response.body

    get node_url(domain_root)

    assert_response :success
    assert_select ".node-public-breadcrumb", count: 0
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
    assert_select ".node-public-breadcrumb-current", "Nested Domain Root"
    assert_select ".node-public-breadcrumb img", count: 0
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

  test "editor actions are visible only to the node owner and superadmin" do
    sign_in(@user)

    get node_url(@draft_node)

    assert_response :success
    assert_select ".node-public-creator-menu-toggle"
    assert_select "details[data-controller='details-menu'][data-action*='click@window->details-menu#closeOutside']"
    assert_select ".node-public-creator-menu-toggle svg[width='18'][height='18']"
    assert_select "header a[href=?]", edit_creator_world_role_assignment_node_path(@draft_node.role_assignment, @draft_node, return_to: node_path(@draft_node)), text: "Modifica"

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
    assert_select ".node-public-creator-menu-toggle"
    assert_select "header a[href=?]", tree_creator_world_role_assignment_node_path(@draft_node.role_assignment, @draft_node), text: "Albero"
    assert_select "header a[href=?]", edit_creator_world_role_assignment_node_path(@draft_node.role_assignment, @draft_node, return_to: node_path(@draft_node)), text: "Modifica"
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
