require "test_helper"

class DomainContentCatalogTest < ActiveSupport::TestCase
  setup { import_posturacorretta_contents }

  test "draft articles are available only in editorial preview" do
    public_slugs = DomainContentCatalog.for_domain("markpostura").map { |article| article.fetch("slug") }
    preview_articles = DomainContentCatalog.for_domain("markpostura", include_scheduled: true)
    draft = preview_articles.find { |article| article.fetch("slug") == "ripensare-l-essere-umano" }

    assert_not_includes public_slugs, "ripensare-l-essere-umano"
    assert draft
    assert draft.fetch("draft")
  end

  test "markpostura and rails4b articles come from Content and its publication state" do
    Content.find_by!(key: "non-devi-cambiare-il-mondo").update!(publication_status: "published", publication_visibility: "public")

    article = DomainContentCatalog.find("markpostura", "non-devi-cambiare-il-mondo")
    assert_equal Date.new(2026, 10, 17), article.fetch("publication_date")
    assert_equal "markpostura", article.fetch("author")
    assert_equal "/markpostura/contenuti/non-devi-cambiare-il-mondo", article.fetch("path")
    assert File.file?(article.fetch("content_path"))
    assert_nil DomainContentCatalog.find("rails4b", "guarda-flowpulse"), "le guide in bozza non si vedono"
    assert DomainContentCatalog.find("rails4b", "guarda-flowpulse", include_scheduled: true)
  end
end
