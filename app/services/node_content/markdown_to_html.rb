class NodeContent::MarkdownToHtml
  RENDERER_OPTIONS = {
    filter_html: true,
    hard_wrap: false,
    link_attributes: { rel: "nofollow noopener" }
  }.freeze

  EXTENSIONS = {
    autolink: true,
    fenced_code_blocks: true,
    no_intra_emphasis: true,
    strikethrough: true,
    tables: true
  }.freeze

  def self.call(markdown)
    return "" if markdown.blank?

    renderer = Redcarpet::Render::HTML.new(RENDERER_OPTIONS)
    Redcarpet::Markdown.new(renderer, EXTENSIONS).render(markdown.to_s)
  end
end
