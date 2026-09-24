require "test_helper"

class LandingContentsControllerTest < ActionDispatch::IntegrationTest
  test "shows the Giardino del Corpo landing with shared project events and redirects old path" do
    assert_equal "/il-giardino-del-corpo", giardino_del_corpo_path

    get "/giardino-del-corpo"
    assert_response :moved_permanently
    assert_redirected_to "/il-giardino-del-corpo"

    get "/il-giardino-del-corpo"
    assert_response :success
    assert_select "h1", text: "Coltiva il corpo, le capacità e le relazioni."
    assert_select "#esperienze"
    assert_select "#eventi"
    assert_select "#luoghi"
    assert_select "#luoghi h3", text: "Giardino del Corpo"
    assert_select "a[href='#{posturacorretta_path}']", minimum: 1
    assert_select "a[href='#{flowpulse_path}']", minimum: 1
    assert_select "a[href='https://il-giardinio-del-corpo-5xsl9ik.gamma.site/']", text: /Vecchia versione/
  end

  test "shows Flowpulse only as the platform presentation" do
    get flowpulse_path

    assert_response :success
    assert_select "h1", text: "Flowpulse"
    assert_select "a[href='#{rails4b_path}']", text: /Rails4Business/, minimum: 1
    assert_select "a[href='#{eventi_path}']", count: 0
    assert_select "a[href^='/flowpulse/contenuti']", count: 0
  end

  test "shows the projects prototype link only to a superadmin" do
    get flowpulse_path
    assert_select "a[href='#{admin_prototype_path(path: "viste_html/flowpulse_sovranita_progetti_community.html")}']", count: 0

    user = User.create!(email_address: "flowpulse-prototype@example.com", password: "password123", password_confirmation: "password123", superadmin: true, active_role: :superadmin)
    user.create_profile!(display_name: "Flowpulse", username: "flowpulse")
    post session_path, params: { email_address: user.email_address, password: "password123" }

    get flowpulse_path
    assert_select "a[href='#{admin_prototype_path(path: "viste_html/flowpulse_sovranita_progetti_community.html")}']", text: "Prototipo progetti e sovranità"
  end

  test "shows contents attributed to markpostura across domains" do
    get markpostura_contents_path

    assert_response :success
    assert_select "h1", text: "Contenuti"
    assert_select "a[href*='posturacorretta.org/posturacorretta/contenuti/']", minimum: 1
    assert_select "a[href='https://posturacorretta.org/posturacorretta/contenuti/la-salute-non-e-un-lusso']", count: 1
    assert_select "a[href='https://rails4b.com/rails4b/contenuti/costruire-un-sistema-economico-nuovo']", count: 1
    assert_match "@markpostura", response.body
  end

  test "redirects the former Rails4Business health article to PosturaCorretta" do
    get rails4b_content_path("la-salute-non-e-un-lusso")

    assert_response :moved_permanently
    assert_redirected_to posturacorretta_articolo_path("la-salute-non-e-un-lusso")
  end

  test "redirects a legacy Flowpulse article to Rails4Business" do
    get flowpulse_content_path("costruire-un-sistema-economico-nuovo")

    assert_response :moved_permanently
    assert_redirected_to rails4b_content_path("costruire-un-sistema-economico-nuovo")
  end

  test "redirects the legacy Flowpulse contents index to Rails4Business" do
    get flowpulse_contents_path

    assert_response :moved_permanently
    assert_redirected_to rails4b_contents_path
  end

  test "shows events organized by markpostura without duplicating their source" do
    get markpostura_events_path

    assert_response :success
    assert_select "h1", text: "Prossimi eventi"
    assert_select "a[href='https://posturacorretta.org/posturacorretta/eventi']", minimum: 1
    assert_match "PosturaCorretta", response.body
  end

  test "renders a dated PosturaCorretta markdown article without changing its slug" do
    get posturacorretta_articolo_path("metodiche-posturali-e-fisiologia")

    assert_response :success
    assert_select "article.editorial-rich-text.editorial-rich-text--blue", count: 1
    assert_match "L'importanza dell'ascolto", response.body
  end
end
