module NodesHelper
  def render_node_markdown(markdown)
    lines = markdown.to_s.lines.map(&:chomp)
    blocks = []
    heading_ids = Hash.new(0)
    index = 0

    while index < lines.length
      line = lines[index]

      if line.blank?
        index += 1
        next
      end

      if (heading = line.match(/\A(\#{1,6})\s+(.+)\z/))
        level = heading[1].length
        title = heading[2]
        blocks << content_tag(:"h#{level}", inline_markdown(title), id: heading_id_for(title, heading_ids))
        index += 1
        next
      end

      if line.match?(/\A[-*]\s+/)
        items = []

        while index < lines.length && lines[index].match?(/\A[-*]\s+/)
          items << content_tag(:li, inline_markdown(lines[index].sub(/\A[-*]\s+/, "")))
          index += 1
        end

        blocks << content_tag(:ul, safe_join(items))
        next
      end

      if line.match?(/\A\d+\.\s+/)
        items = []

        while index < lines.length && lines[index].match?(/\A\d+\.\s+/)
          items << content_tag(:li, inline_markdown(lines[index].sub(/\A\d+\.\s+/, "")))
          index += 1
        end

        blocks << content_tag(:ol, safe_join(items))
        next
      end

      paragraph = [line]
      index += 1

      while index < lines.length && lines[index].present? && !markdown_block_start?(lines[index])
        paragraph << lines[index]
        index += 1
      end

      blocks << content_tag(:p, inline_markdown(paragraph.join(" ")))
    end

    safe_join(blocks)
  end

  private

  def markdown_block_start?(line)
    line.match?(/\A\#{1,6}\s+|\A[-*]\s+|\A\d+\.\s+/)
  end

  def inline_markdown(text)
    html = ERB::Util.html_escape(text.to_s)
    html = html.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
    html = html.gsub(/\*(.+?)\*/, '<em>\1</em>')
    html.html_safe
  end

  def heading_id_for(text, heading_ids)
    base = text.to_s
      .gsub(/\*\*(.+?)\*\*/, '\1')
      .gsub(/\*(.+?)\*/, '\1')
      .parameterize
      .presence || "section"

    heading_ids[base] += 1
    heading_ids[base] == 1 ? base : "#{base}-#{heading_ids[base]}"
  end
end
