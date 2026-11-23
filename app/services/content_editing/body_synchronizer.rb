require "digest"

module ContentEditing
  # Mantiene Markdown e Lexxy come due rappresentazioni dello stesso Content.
  # Non risolve mai automaticamente un conflitto: conserva entrambe le versioni.
  class BodySynchronizer
    def initialize(content)
      @content = content
    end

    def bootstrap!
      return content if content.markdown_checksum.present? || content.lexxy_checksum.present?

      if content.editor == "lexxy" && lexxy_html.present?
        accept_lexxy!(lexxy_html)
      elsif content.body_md.present?
        accept_markdown!(content.body_md)
      elsif lexxy_html.present?
        accept_lexxy!(lexxy_html)
      else
        content.update!(sync_status: "clean")
        content
      end
    end

    def import_markdown!(markdown)
      markdown = markdown.to_s
      lexxy_changed = changed?(lexxy_html, content.lexxy_checksum)

      if lexxy_changed && changed?(markdown, content.markdown_checksum)
        content.update!(
          body_md: markdown,
          markdown_checksum: digest(markdown),
          markdown_updated_at: Time.current,
          sync_status: "conflict"
        )
        content
      else
        accept_markdown!(markdown)
      end
    end

    def import_lexxy!(html)
      html = html.to_s
      markdown_changed = changed?(content.body_md.to_s, content.markdown_checksum)

      if markdown_changed && changed?(html, content.lexxy_checksum)
        content.body = html
        content.assign_attributes(
          lexxy_checksum: digest(rich_text_html(content.body)),
          lexxy_updated_at: Time.current,
          sync_status: "conflict"
        )
        content.save!
        content
      else
        accept_lexxy!(html)
      end
    end

    def resolve_with_markdown!(markdown = content.body_md)
      accept_markdown!(markdown.to_s)
    end

    def resolve_with_lexxy!(html = lexxy_html)
      accept_lexxy!(html.to_s)
    end

    private

      attr_reader :content

      def accept_markdown!(markdown)
        now = Time.current
        content.body = NodeContent::MarkdownToHtml.call(markdown)
        html = rich_text_html(content.body)
        content.assign_attributes(
          body_md: markdown,
          editor: "markdown",
          sync_status: "clean",
          markdown_checksum: digest(markdown),
          lexxy_checksum: digest(html),
          markdown_updated_at: now,
          lexxy_updated_at: now
        )
        content.save!
        content
      end

      def accept_lexxy!(html)
        now = Time.current
        content.body = html
        stored_html = rich_text_html(content.body)
        markdown = NodeContent::HtmlToMarkdown.call(stored_html)
        content.assign_attributes(
          body_md: markdown,
          editor: "lexxy",
          sync_status: "clean",
          markdown_checksum: digest(markdown),
          lexxy_checksum: digest(stored_html),
          markdown_updated_at: now,
          lexxy_updated_at: now
        )
        content.save!
        content
      end

      def lexxy_html
        rich_text_html(content.body)
      end

      def rich_text_html(rich_text)
        return "" if rich_text.blank?
        return rich_text.body.to_html if rich_text.respond_to?(:body) && rich_text.body.present?

        rich_text.to_s
      end

      def changed?(value, checksum)
        checksum.present? && digest(value.to_s) != checksum
      end

      def digest(value)
        Digest::SHA256.hexdigest(value.to_s)
      end
  end
end
