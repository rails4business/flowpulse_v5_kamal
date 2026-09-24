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
    assert_select "nav a[href='/impegno']", text: "Home"
    assert_select "a[href='#{brand_changelog_entry_path("impegno", "esperienza-session-slot-commitment")}']"
  end

  test "Brand changelog navigation returns to the Brand home" do
    host! "localhost"
    get brand_changelog_path("posturacorretta")

    assert_response :success
    assert_select "nav a[href='/posturacorretta']", text: "PosturaCorretta"
    assert_select "nav a[href='/posturacorretta']", text: "Home"
    assert_select "a[href='#{brand_changelog_entry_path("posturacorretta", "percorso-educativo-e-programma-lezioni")}']", text: /Percorso educativo/

    get brand_changelog_entry_path("posturacorretta", "percorso-educativo-e-programma-lezioni")
    assert_response :success
    assert_select "nav a[href='/posturacorretta']", text: "Home"
  end

  test "local Flowpulse index links the separate Brand changelogs" do
    host! "localhost"
    get changelog_path

    assert_response :success
    assert_select "a[href='#{brand_changelog_path("posturacorretta")}']", text: /PosturaCorretta/
    assert_select "a[href='#{brand_changelog_path("svuotamente")}']", text: /SvuotaMente/
    assert_select "a[href='#{brand_changelog_entry_path("posturacorretta", "percorso-educativo-e-programma-lezioni")}']", count: 0
  end

  test "every configured Brand uses the shared changelog index" do
    host! "localhost"

    ChangelogRepository.catalog.each_value do |brand|
      get brand_changelog_path(brand.fetch("key"))

      assert_response :success, "Changelog non renderizzato per #{brand.fetch("key")}"
      assert_select "nav a[href='#{brand.fetch("public_path")}']", text: brand.fetch("label")
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
      posturacorretta_url => brand_changelog_path("posturacorretta"),
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
