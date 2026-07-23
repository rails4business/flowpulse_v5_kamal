# app/helpers/markdown_helper.rb
require "redcarpet"
require "uri"

# Prova a caricare Rouge (per evidenziare il codice). Se manca, fai fallback.
begin
  require "rouge"
  require "rouge/plugins/redcarpet"
  MarkdownRenderer = Class.new(Redcarpet::Render::HTML) do
    include Rouge::Plugins::Redcarpet
  end
rescue LoadError
  MarkdownRenderer = Redcarpet::Render::HTML
end

module MarkdownHelper
  YOUTUBE_SHORTCODE_RE = /\[youtube\s+([^\]]+)\]/.freeze
  YOUTUBE_TOKEN_ID_RE = /\[\[YOUTUBE_ID:([A-Za-z0-9_-]{6,})\]\]/.freeze
  YOUTUBE_TOKEN_LIST_RE = /\[\[YOUTUBE_LIST:([A-Za-z0-9_-]{6,})\]\]/.freeze
  YOUTUBE_IFRAME_RE = /<iframe\b[^>]*\bsrc=(["'])([^"']+)\1[^>]*>\s*<\/iframe>/i.freeze

  def markdown(text)
    return "".html_safe if text.blank?

    renderer = MarkdownRenderer.new(
      filter_html:   true,
      hard_wrap:     false,
      with_toc_data: true
    )

    md = Redcarpet::Markdown.new(
      renderer,
      fenced_code_blocks: true,
      autolink:           true,
      tables:             true,
      strikethrough:      true,
      underline:          true,
      highlight:          true,
      quote:              true,
      footnotes:          true,
      lax_spacing:        true,
      space_after_headers: true
    )

    source = text.to_s.gsub(/\r\n?/, "\n")
    source = source.gsub(YOUTUBE_IFRAME_RE) do
      youtube_token_from_embed_src(Regexp.last_match(2)) || ""
    end
    source = source.gsub(YOUTUBE_SHORTCODE_RE) do
      attrs = Regexp.last_match(1)
      youtube_token_for(attrs) || ""
    end

    html = md.render(source)
    html = html.gsub(YOUTUBE_TOKEN_ID_RE) do
      video_id = Regexp.last_match(1)
      build_youtube_embed(%(id="#{video_id}")) || ""
    end
    html = html.gsub(YOUTUBE_TOKEN_LIST_RE) do
      list_id = Regexp.last_match(1)
      build_youtube_embed(%(list="#{list_id}")) || ""
    end
    sanitize(
      html,
      tags:        permitted_tags,
      attributes:  permitted_attributes,
      protocols:   %w[http https mailto]
    ).html_safe
  end

  def inline_markdown(text)
    return "".html_safe if text.blank?

    html = markdown(text.to_s.gsub(/\s*\n+\s*/, " ")).to_s
    html = html.delete_prefix("<p>").sub(%r{</p>\s*\z}, "")
    html.html_safe
  end

  private

  def permitted_tags
    %w[p br strong em a ul ol li pre code blockquote h1 h2 h3 h4 h5 h6
       table thead tbody tr th td hr img iframe]
  end

  def permitted_attributes
    %w[href title src alt width height allow allowfullscreen frameborder referrerpolicy]
  end

  def build_youtube_embed(attrs)
    id = extract_attr(attrs, "id")
    list = extract_attr(attrs, "list")

    return if id.blank? && list.blank?

    if id.present?
      video_id = sanitize_youtube_token(id)
      return unless video_id

      src = "https://www.youtube-nocookie.com/embed/#{video_id}"
    else
      list_id = sanitize_youtube_token(list)
      return unless list_id

      src = "https://www.youtube-nocookie.com/embed/videoseries?list=#{ERB::Util.url_encode(list_id)}"
    end

    %(<iframe width="560" height="315" src="#{src}" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>)
  end

  def youtube_token_for(attrs)
    id = extract_attr(attrs, "id")
    list = extract_attr(attrs, "list")
    return if id.blank? && list.blank?

    if id.present?
      video_id = sanitize_youtube_token(id)
      return unless video_id

      return "[[YOUTUBE_ID:#{video_id}]]"
    end

    list_id = sanitize_youtube_token(list)
    return unless list_id

    "[[YOUTUBE_LIST:#{list_id}]]"
  end

  def extract_attr(text, name)
    match = text.match(/#{Regexp.escape(name)}=(?:"([^"]+)"|([^\s]+))/)
    match && (match[1] || match[2])
  end

  def sanitize_youtube_token(token)
    return unless token.is_a?(String)

    token = token.strip
    return unless token.match?(/\A[A-Za-z0-9_-]{6,}\z/)

    token
  end

  def youtube_token_from_embed_src(src)
    return if src.blank?

    uri = URI.parse(src)
    host = uri.host.to_s.downcase
    path = uri.path.to_s
    query = URI.decode_www_form(uri.query.to_s).to_h

    if host.include?("youtu.be")
      id = sanitize_youtube_token(path.delete_prefix("/"))
      return "[[YOUTUBE_ID:#{id}]]" if id
    end

    return unless host.include?("youtube.com") || host.include?("youtube-nocookie.com")

    if path.start_with?("/embed/videoseries")
      list_id = sanitize_youtube_token(query["list"].to_s)
      return "[[YOUTUBE_LIST:#{list_id}]]" if list_id
    elsif path.start_with?("/embed/")
      id = sanitize_youtube_token(path.delete_prefix("/embed/").to_s.split("/").first)
      return "[[YOUTUBE_ID:#{id}]]" if id
    elsif path == "/watch"
      id = sanitize_youtube_token(query["v"].to_s)
      return "[[YOUTUBE_ID:#{id}]]" if id
    end

    nil
  rescue URI::InvalidURIError
    nil
  end
end
