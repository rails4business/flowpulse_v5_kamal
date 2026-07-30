require "test_helper"

class MarkdownHelperTest < ActionView::TestCase
  test "document toc includes only h1 h2 and h3 linked to rendered ids" do
    source = <<~MARKDOWN
      # Titolo
      Testo normale.
      ## Sezione
      - elemento elenco

      ### Dettaglio

      #### Titolo escluso
    MARKDOWN

    fragment = Nokogiri::HTML.fragment(markdown_toc(source))

    assert_equal ["Titolo", "Sezione", "Dettaglio"], fragment.css("a").map(&:text)
    assert_equal ["#titolo", "#sezione", "#dettaglio"], fragment.css("a").map { |link| link["href"] }
    assert_not_includes fragment.text, "Testo normale"
    assert_not_includes fragment.text, "elemento elenco"
    assert_not_includes fragment.text, "Titolo escluso"
  end
end
