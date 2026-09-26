require "test_helper"

class ChangelogControllerTest < ActionDispatch::IntegrationTest
  test "renders only Flowpulse entries and the separate domain directory" do
    get changelog_url

    assert_response :success
    assert_select "h1", "Changelog"
    assert_select "article h3", text: "Stato del pilota dell’ecosistema"
    assert_select "article h3", text: "Percorso educativo e programma delle lezioni", count: 0
    assert_select "a[href='https://1impegno.it/changelog']", text: /1Impegno/
    assert_select "a[href='#{changelog_entry_path("stato-pilota-ecosistema")}']"
  end

  test "renders the changelog selected by the request domain" do
    host! "1impegno.it"
    get changelog_path

    assert_response :success
    assert_select "header p", text: "1Impegno"
    assert_select "article", count: 2
    assert_select "article h3", text: "Il primo nucleo operativo di 1Impegno"
  end

  test "renders a local preview and preserves its Brand in entry links" do
    host! "localhost"
    get brand_changelog_path("impegno")

    assert_response :success
    assert_select "a[href='/impegno']"
    assert_select "a[href='#{brand_changelog_entry_path("impegno", "esperienza-session-slot-commitment")}']"
  end

  test "Brand changelog navigation returns to the Brand home" do
    host! "localhost"
    get posturacorretta_changelog_path

    assert_response :success
    assert_select "a[href='/posturacorretta']"
    assert_select "a[href='#{posturacorretta_changelog_entry_path("percorso-educativo-e-programma-lezioni")}']", text: /Percorso educativo/

    get posturacorretta_changelog_entry_path("percorso-educativo-e-programma-lezioni")
    assert_response :success
    assert_select "a[href='/posturacorretta']"
  end

  test "local Flowpulse index links the separate Brand changelogs" do
    host! "localhost"
    get changelog_path

    assert_response :success
    assert_select "a[href='#{posturacorretta_changelog_path}']", text: /PosturaCorretta/
    assert_select "a[href='#{brand_changelog_path("svuotamente")}']", text: /SvuotaMente/
    assert_select "a[href='#{brand_changelog_entry_path("posturacorretta", "percorso-educativo-e-programma-lezioni")}']", count: 0
  end

  test "every configured Brand uses the shared changelog index" do
    host! "localhost"

    ChangelogRepository.catalog.each_value do |brand|
      get brand_changelog_path(brand.fetch("key"))

      assert_response :success, "Changelog non renderizzato per #{brand.fetch("key")}"
      assert_select "a[href='#{brand.fetch("public_path")}']"
      assert_select "h1", text: "Changelog"
      assert_select "#timeline-title", text: "Aggiornamenti"
      assert_select "ol article", minimum: 1
    end
  end

  test "renders a Markdown changelog entry for the current domain" do
    host! "1impegno.it"
    get changelog_entry_path("esperienza-session-slot-commitment")

    assert_response :success
    assert_select "h1", "Il primo nucleo operativo di 1Impegno"
    assert_select ".editorial-rich-text h1", text: "Il primo nucleo operativo di 1Impegno"
    assert_select ".editorial-rich-text code", text: /DataExperience/
  end

  test "Radioestesia preview changelog is reserved to superadmin and uses its navigation" do
    get radioestesia_changelog_path
    assert_redirected_to new_session_path(return_to: radioestesia_changelog_path)

    user = User.create!(
      email_address: "radioestesia-changelog@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )
    user.create_profile!(display_name: "Radioestesia Changelog")
    post session_url, params: { email_address: user.email_address, password: "password123" }

    get radioestesia_changelog_path

    assert_response :success
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_select "nav[aria-label='Navigazione Radioestesia'] a[href='#{radioestesia_path}']", text: "Home"
    assert_select "nav[aria-label='Navigazione Radioestesia'] a[href='#{radioestesia_changelog_path}']", text: "Changelog"
    assert_select "a[href='#{radioestesia_changelog_entry_path("anteprima-flowpulse")}']"
  end

  test "returns not found for an unknown local Brand" do
    host! "localhost"
    get brand_changelog_path("non-esiste")

    assert_response :not_found
  end

  test "main public homes expose their scoped changelog from the footer" do
    host! "localhost"
    {
      flowpulse_url => changelog_path,
      rails4b_url => brand_changelog_path("rails4business"),
      genera_impresa_url => brand_changelog_path("generaimpresa"),
      impegno_url => brand_changelog_path("impegno"),
      giardino_del_corpo_url => brand_changelog_path("ilgiardinodelcorpo"),
      markpostura_url => brand_changelog_path("markpostura"),
      posturacorretta_url => posturacorretta_changelog_path,
      percorso_integrato_url => brand_changelog_path("percorso-integrato"),
      cantachetipassa_url => brand_changelog_path("cantachetipassa"),
      svuotamente_url => brand_changelog_path("svuotamente"),
      igieneposturale_url => brand_changelog_path("igieneposturale")
    }.each do |page, changelog_link|
      get page
      assert_response :success
      assert_select "footer a[href='#{changelog_link}']", text: "Changelog"
    end
  end
end
