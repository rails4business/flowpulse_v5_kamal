require "test_helper"

class EditorialHelperTest < ActionView::TestCase
  test "renders safe markdown used by YAML editorial components" do
    fragment = Nokogiri::HTML.fragment(editorial_markdown(<<~MARKDOWN))
      Testo **importante** e *corsivo*.

      - primo punto
      - secondo punto
    MARKDOWN

    assert_equal "importante", fragment.at_css("strong").text
    assert_equal "corsivo", fragment.at_css("em").text
    assert_equal ["primo punto", "secondo punto"], fragment.css("ul li").map(&:text)
  end
end
