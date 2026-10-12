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
      node_type: "project",
      status: "published"
    )
    # create a second node to test specific domain node vs creator home node
    @other_node = Node.create!(
      role_assignment: @role_assignment,
      title: "Specific Target Node",
      node_type: "project",
      status: "published"
    )
  end

  test "renders fallback home for unconfigured host" do
    get root_url

    assert_response :success
    assert_includes response.body, "Flowpulse"
  end

  test "renders configured domain target" do
    Domain.create!(
      hostname: "posturacorretta.org",
      target_controller: "landing",
      target_action: "posturacorretta",
      site_key: "posturacorretta_it",
      locale: "it",
      site_title: "PosturaCorretta",
      site_description: "Percorsi per conoscere e prendersi cura del corpo.",
      favicon_url: "https://cdn.example.com/posturacorretta-icon.png",
      social_image_url: "https://cdn.example.com/posturacorretta-social.png"
    )
    host! "posturacorretta.org"

    get root_url

    assert_response :success
    assert_includes response.body, "PosturaCorretta"
    assert_select "title", text: "Percorso PosturaCorretta · Educazione alla salute"
    assert_select "meta[name='description'][content='Il percorso educativo alla salute grazie alle metodiche posturali. Scopri come funziona il tuo corpo e riattiva i tuoi sistemi.']"
    assert_select "link[rel='icon'][href='https://cdn.example.com/posturacorretta-icon.png']"
    assert_select "meta[property='og:title'][content='Percorso PosturaCorretta · Educazione alla salute']"
    assert_select "meta[property='og:description'][content='Il percorso educativo alla salute grazie alle metodiche posturali. Scopri come funziona il tuo corpo e riattiva i tuoi sistemi.']"
    assert_select "meta[property='og:image'][content='https://cdn.example.com/posturacorretta-social.png']"
    assert_select "meta[name='twitter:image'][content='https://cdn.example.com/posturacorretta-social.png']"
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

  test "renders Rails4Business home on its domain" do
    Domain.create!(
      hostname: "rails4b.com",
      target_controller: "landing",
      target_action: "rails4b",
      locale: "it"
    )
    host! "rails4b.com"

    get root_url

    assert_response :success
    assert_select "h1", text: "Problemi da risolvere. Skill da costruire e riutilizzare."
    assert_select "h2", text: "Ogni persona può ideare o realizzare"
    assert_select "h2", text: "Il canale YouTube come sottoprogetto"
  end

  test "renders markpostura domain from its editorial Site" do
    Domain.create!(hostname: "markpostura.it", site_key: "markpostura_it", locale: "it")
    host! "markpostura.it"

    get root_url

    assert_response :success
    assert_select "h1", text: "Problemi, idee e soluzioni da mettere alla prova"
    assert_select "#direzioni"
    assert_select "nav a[href='#{markpostura_weekplan_path}']", text: "Orario"
    assert_select "#weekplan", count: 0
    assert_select "img[src*='hero_markpostura-720']"
    assert_select "meta[name='robots'][content='noindex,nofollow']", count: 0
  end

  test "renders a configured language Site under its locale prefix" do
    Domain.create!(
      hostname: "markpostura.it",
      site_key: "markpostura_it",
      sites: { it: "markpostura_it" },
      locale: "it"
    )
    host! "markpostura.it"

    get localized_domain_root_url(locale: "it")

    assert_response :success
    assert_select "h1", text: "Problemi, idee e soluzioni da mettere alla prova"
  end

  test "does not publish an undeclared language variant" do
    Domain.create!(
      hostname: "markpostura.it",
      sites: { it: "markpostura_it" },
      locale: "it"
    )
    host! "markpostura.it"

    get localized_domain_root_url(locale: "en")

    assert_response :not_found
  end

  test "uses the canonical domain without query parameters and emits valid structured data" do
    @other_node.update!(node_type: "professional")
    Domain.create!(
      hostname: "profile.example",
      node: @other_node,
      target_controller: "landing",
      target_action: "flowpulse",
      locale: "it",
      site_title: "Profilo pubblico",
      site_description: "Descrizione pubblica"
    )
    host! "profile.example"

    get root_url(tab: "method", utm_source: "test")

    assert_response :success
    assert_select "link[rel='canonical'][href='https://profile.example/']"
    script = css_select("script[type='application/ld+json']").first
    data = JSON.parse(script.text)
    identity = data.fetch("@graph").find { |item| item["@id"] == "https://profile.example/#identity" }
    assert_equal "Person", identity.fetch("@type")
    assert_equal "Specific Target Node", identity.fetch("name")
  end

  test "redirects a MarkPostura alias to the canonical editorial domain" do
    Domain.create!(hostname: "markpostura.it", site_key: "markpostura_it", locale: "it")
    Domain.create!(hostname: "www.markpostura.it", canonical_host: "markpostura.it", locale: "it")
    host! "www.markpostura.it"

    get root_url

    assert_redirected_to "http://markpostura.it/"
  end

  test "renders GeneraImpresa on its domain with domain metadata" do
    Domain.create!(
      hostname: "generaimpresa.it",
      target_controller: "brands/genera_impresa",
      target_action: "index",
      locale: "it",
      site_title: "GeneraImpresa ufficiale",
      site_description: "Catalogo pubblico dei progetti",
      favicon_url: "https://cdn.example.com/generaimpresa.png"
    )
    host! "generaimpresa.it"

    get root_url

    assert_response :success
    assert_includes response.body, "GeneraImpresa"
    assert_select "h2", text: "Brand personali"
    assert_select "h2", text: "Brand progetto"
    assert_select "#brand-personali a[href='#{genera_impresa_brand_path("radioestesia")}']", text: /Radioestesia e Benessere/
    assert_select "meta[name='description'][content=?]", GeneraImpresaCatalog.load.site.fetch("description")
    assert_select "link[rel='icon'][href='https://cdn.example.com/generaimpresa.png']"
  end

  test "renders Percorso Integrato on its own domain" do
    Domain.create!(
      hostname: "percorsointegrato.it",
      target_controller: "brands/percorso_integrato",
      target_action: "index",
      locale: "it",
      site_title: "Percorso Integrato"
    )
    host! "percorsointegrato.it"

    get root_url

    assert_response :success
    assert_select "h1", text: "Costruisci un percorso personale, leggibile e coordinato."
    assert_select "title", text: /Percorso Integrato/
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

  test "redirects a domain with a draft private root node to GeneraImpresa" do
    draft_node = Node.create!(
      role_assignment: @role_assignment,
      title: "Igiene Posturale",
      slug: "igiene-posturale",
      node_type: "project",
      status: "draft",
      visibility: "private"
    )
    Domain.create!(hostname: "igieneposturale.it", target_controller: "landing", target_action: "igieneposturale", node: draft_node, locale: "it")
    host! "igieneposturale.it"

    get root_url

    assert_redirected_to "http://generaimpresa.it/generaimpresa"
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
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
    assert_select "h1", text: /Trova la giusta posizione/
    assert_select "h1", text: "Specific Target Node", count: 0
    assert_select "h1", text: "Creator Home Node", count: 0
    assert_select "script[type='application/ld+json']", text: /Specific Target Node/
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

  test "renders Giardino del Corpo for ilgiardinodelcorpo.it host" do
    host! "ilgiardinodelcorpo.it"

    get root_url

    assert_response :success
    assert_includes response.body, "Il Giardino del Corpo"
    assert_select "h1", text: "Coltiva il corpo, le capacità e le relazioni."
  end
end
