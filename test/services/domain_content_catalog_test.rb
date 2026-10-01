require "test_helper"

class DomainContentCatalogTest < ActiveSupport::TestCase
  test "draft articles are available only in editorial preview" do
    public_slugs = DomainContentCatalog.for_domain("markpostura").map { |article| article.fetch("slug") }
    preview_articles = DomainContentCatalog.for_domain("markpostura", include_scheduled: true)
    draft = preview_articles.find { |article| article.fetch("slug") == "ripensare-l-essere-umano" }

    assert_not_includes public_slugs, "ripensare-l-essere-umano"
    assert draft
    assert draft.fetch("draft")
  end
end
