require "test_helper"

class GeneraImpresaControllerTest < ActionDispatch::IntegrationTest
  test "renders the public brand and project catalog" do
    get genera_impresa_url
    assert_response :success
    assert_select "a[href=?]", new_session_path(return_to: genera_impresa_path), text: "Accedi"
    assert_select "h1", /Dalle idee ai progetti/
    assert_includes response.body, "PosturaCorretta"
    assert_includes response.body, "FlowPulse"
    assert_select "h2", text: "Brand personali"
    assert_select "h2", text: "Brand progetto"
    assert_not_includes response.body, "Davide Cattaneo"
    assert_select "#brand-personali" do
      assert_select "a[href='#{genera_impresa_brand_path("radioestesia")}']", text: /Radioestesia e Benessere/
    end
    assert_select "#brand-progetto a[href='#{genera_impresa_brand_path("radioestesia")}']", count: 0
  end

  test "renders a brand with many projects" do
    get genera_impresa_brand_url("posturacorretta")
    assert_response :success
    assert_select "h1", "PosturaCorretta"
    assert_select "h2", "Progetti del brand"
  end

  test "renders a brand with one project" do
    get genera_impresa_brand_url("flowpulse")
    assert_response :success
    assert_select "h1", "FlowPulse"
    assert_select "article", count: 1
  end

  test "renders Radioestesia as a public brand preview hosted by GeneraImpresa" do
    get genera_impresa_brand_url("radioestesia")

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "nav[aria-label='Navigazione Radioestesia']"
    assert_select "a[href='#{radioestesia_page_path("percorsi")}']"
    assert_select "a[href='#{radioestesia_page_path("contenuti")}']"
  end

  test "renders SvuotaMente as a brand with its webapp project" do
    get genera_impresa_brand_url("svuotamente")
    assert_response :success
    assert_select "h1", "SvuotaMente"
    assert_includes response.body, "Webapp SvuotaMente"

    get genera_impresa_project_url("webapp-svuotamente")
    assert_response :success
    assert_select "a[href=?]", svuotamente_path, text: /Apri la webapp/
  end

  test "renders Davide Cattaneo as a personal brand in construction" do
    get genera_impresa_brand_url("davide-cattaneo")
    assert_redirected_to "https://percorsointegrato.it#{percorso_integrato_professional_path("davide-cattaneo")}"

    sign_in_as_superadmin
    get genera_impresa_brand_url("davide-cattaneo")
    assert_redirected_to "https://percorsointegrato.it#{percorso_integrato_professional_path("davide-cattaneo")}"
  end

  test "renders Davide swimming exercise sheet and its prototype images" do
    sign_in_as_superadmin
    get genera_impresa_brand_material_url("davide-cattaneo", "scheda-nuoto")
    assert_response :success
    assert_select "h1", "Preparazione al nuoto · 10 esercizi"
    assert_select "table tbody tr", count: 10
    assert_select ".gym-sheet__mobile article", count: 10
    assert_select "button", text: "Stampa scheda"
    assert_includes response.body, "Allungamento in alto"
    assert_includes response.body, "Spalle e trapezi"

    get genera_impresa_brand_material_image_url("davide-cattaneo", "scheda-nuoto", 1)
    assert_response :success
    assert_equal "image/gif", response.media_type
  end

  test "renders a single exercise from Davide swimming sheet" do
    sign_in_as_superadmin
    get genera_impresa_brand_material_exercise_url("davide-cattaneo", "scheda-nuoto", 1)

    assert_response :success
    assert_select "h1", "Allungamento in alto"
    assert_includes response.body, "Esercizio 01 di 10"
    assert_includes response.body, "Spalle, tronco e asse del corpo"
    assert_includes response.body, "15–25 secondi × 2"
    assert_select "[data-exercise-animation]"
    assert_select "button[data-speed-control]", text: "Velocità: normale"
    assert_select "button[data-pause-control]", text: "Pausa"
    assert_select "a[href=?]", genera_impresa_brand_material_exercise_path("davide-cattaneo", "scheda-nuoto", 2), text: /Successivo/
  end

  test "renders a public project page" do
    get genera_impresa_project_url("piattaforma-flowpulse-rails4business")
    assert_response :success
    assert_includes response.body, "Step del progetto"
  end

  test "Ripartire con Dash is a public lightweight project landing" do
    get genera_impresa_project_url("ripartire-con-dash")
    assert_response :success
    assert_select "h1", "Ripartire con Dash"
    assert_select "a[href=?]", rails4b_content_path("riprenderci-la-politica-partendo-dall-economia")
    assert_select "a[href=?]", impegno_path(area: "problems")
    assert_includes response.body, "In elaborazione"
    assert_includes response.body, "Categorie da aprire"
    assert_includes response.body, "più di 20.000 abitanti"
    assert_select "a[href=?]", genera_impresa_project_step_path("ripartire-con-dash", "apri-la-lista-del-comune"), text: /Apri la lista del tuo comune/
  end

  test "renders every operational content of Ripartire with Dash" do
    get genera_impresa_project_step_url("ripartire-con-dash", "aiuta-ad-aprire-il-portafoglio")

    assert_response :success
    assert_select "h1", "Trova e aiuta ad aprire un portafoglio"
    assert_select "h2", "Prima lista di controllo"
    assert_select "li", text: /Spiega a che cosa serve/
    assert_select "a[href=?]", genera_impresa_project_step_path("ripartire-con-dash", "trova-un-bisogno-reale"), text: /Trova un bisogno reale/
  end

  test "owner sees managed brands domains and FlowPulse administration links" do
    owner = User.create!(email_address: "genera-owner@example.com", password: "password123", password_confirmation: "password123")
    profile = owner.create_profile!(display_name: "Genera Owner", username: "genera_owner")
    assignment = RoleAssignment.create!(profile: profile, role: :creator_of_worlds)
    brand = Node.create!(title: "Brand del proprietario", slug: "brand-del-proprietario", role_assignment: assignment, status: "published")
    Domain.create!(hostname: "brand-proprietario.test", node: brand, role_assignment: assignment, primary: true, active: true)
    post session_url, params: { email_address: owner.email_address, password: "password123" }

    get genera_impresa_url

    assert_response :success
    assert_select "summary.profile-menu-toggle[aria-label='Apri menu profilo']", count: 1
    assert_select "a[href='#{genera_impresa_path}#i-miei-brand']", text: "I miei Brand"
    assert_select "form[action=?]", session_path
    assert_select "#i-miei-brand h2", "I tuoi Brand e domini"
    assert_select "#i-miei-brand h3", "Brand del proprietario"
    assert_select "a[href='https://brand-proprietario.test']", text: /brand-proprietario\.test/
    assert_select "a[href='#{brand_admin_nodes_path(brand.slug)}']", text: "Nodi"
    assert_select "a[href='#{brand_admin_data_commitments_path(brand.slug)}']", text: "Richieste"
    assert_select "a[href='#{brand_admin_privacy_path(brand.slug)}']", text: "Privacy"
  end

  test "public catalog does not expose the private control room" do
    get genera_impresa_url

    assert_select "#i-miei-brand", count: 0
    assert_select "a", text: "I miei Brand", count: 0
  end

  test "building brands are private to superadmin" do
    get genera_impresa_brand_url("inside-adventure")
    assert_response :not_found

    sign_in_as_superadmin
    get genera_impresa_url
    assert_response :success
    assert_not_includes response.body, "Davide Cattaneo"
    assert_includes response.body, "Inside Adventure"
    assert_includes response.body, "Vista superadmin"
  end

  private

  def sign_in_as_superadmin
    user = User.create!(email_address: "superadmin-#{SecureRandom.hex(4)}@example.com", password: "password123", password_confirmation: "password123", active_role: :superadmin, superadmin: true)
    post session_url, params: { email_address: user.email_address, password: "password123" }
  end
end
