class NodeContent::HtmlToMarkdown
  BLOCK_TAGS = %w[address article aside div figure figcaption footer header main nav p section].freeze

  def self.call(html)
    new(html).call
  end

  def initialize(html)
    @fragment = Nokogiri::HTML5.fragment(html.to_s)
  end

  def call
    markdown = @fragment.children.map { |node| convert(node) }.join
    markdown.gsub(/[ \t]+\n/, "\n").gsub(/\n{3,}/, "\n\n").strip
  end

  private

  def convert(node, list_depth: 0)
    return node.text if node.text?
    return "" unless node.element?

    inner = node.children.map { |child| convert(child, list_depth: list_depth) }.join

    case node.name
    when "h1", "h2", "h3", "h4", "h5", "h6"
      "#{'#' * node.name.delete_prefix('h').to_i} #{inner.strip}\n\n"
    when *BLOCK_TAGS
      "#{inner.strip}\n\n"
    when "br"
      "\n"
    when "strong", "b"
      "**#{inner.strip}**"
    when "em", "i"
      "*#{inner.strip}*"
    when "s", "del", "strike"
      "~~#{inner.strip}~~"
    when "code"
      node.parent&.name == "pre" ? inner : "`#{inner.strip}`"
    when "pre"
      language = node.at_css("code")&.[]("class").to_s[/language-([\w+-]+)/, 1]
      "```#{language}\n#{node.text.rstrip}\n```\n\n"
    when "a"
      href = node["href"].to_s
      href.present? ? "[#{inner.strip.presence || href}](#{href})" : inner
    when "img"
      "![#{node['alt']}](#{node['src']})"
    when "ul", "ol"
      node.element_children.each_with_index.map do |item, index|
        prefix = node.name == "ol" ? "#{index + 1}. " : "- "
        indent = "  " * list_depth
        content = item.children.map { |child| convert(child, list_depth: list_depth + 1) }.join.strip
        "#{indent}#{prefix}#{content}\n"
      end.join + "\n"
    when "li"
      inner
    when "blockquote"
      inner.strip.lines.map { |line| "> #{line}" }.join + "\n\n"
    when "hr"
      "---\n\n"
    when "table"
      "#{node.to_html}\n\n"
    when "action-text-attachment"
      attachment_markdown(node)
    else
      inner
    end
  end

  def attachment_markdown(node)
    url = node["url"].presence || node["href"].presence
    label = node["caption"].presence || node["filename"].presence || "Allegato"
    url ? "[#{label}](#{url})" : node.to_html
  end
end
