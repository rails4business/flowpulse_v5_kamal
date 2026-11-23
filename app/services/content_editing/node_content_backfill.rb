module ContentEditing
  # Collega o crea lo show Content di un Node senza eliminare il vecchio NodeContent.
  class NodeContentBackfill
    Result = Data.define(:node, :content, :action, :legacy_body_present)

    def initialize(node)
      @node = node
    end

    def call
      content = node.show_content || inferred_course_content || build_content
      action = content.new_record? ? "created" : "linked"
      content.save! if content.new_record?

      link_content!(content) unless content.node_id == node.id
      synchronize_legacy_body!(content) if legacy_body_present? && content.body_md.blank? && content.body.blank?
      node.update!(show_content: content)

      Result.new(node:, content:, action:, legacy_body_present: legacy_body_present?)
    end

    private

      attr_reader :node

      def inferred_course_content
        return unless node.view_type == "course"

        Content.where(id: node.children.unscope(:order).joins(:editorial_contents)
          .merge(Content.where(role: "chapter"))
          .select("contents.parent_id"))
          .where(role: "introduction")
          .order("contents.position", "contents.id")
          .first
      end

      def build_content
        Content.new(
          node:,
          profile: node.role_assignment&.profile,
          key: unique_key,
          slug: "introduzione",
          format: "post",
          role: "introduction",
          placement: "after_body",
          position: 0,
          title: node.title,
          description: node.description,
          publication_status: node.status,
          publication_visibility: node.visibility
        )
      end

      def unique_key
        base = "node-#{node.slug}-introduction"
        return base unless Content.exists?(key: base)

        "#{base}-#{node.id}"
      end

      def link_content!(content)
        node.outgoing_content_links.find_or_create_by!(target_content: content, kind: "show") do |link|
          link.position = 0
        end
      end

      def synchronize_legacy_body!(content)
        legacy = node.content
        if legacy.editor == "lexxy" && legacy.body.present?
          ContentEditing::BodySynchronizer.new(content).import_lexxy!(legacy.body.to_s)
        elsif legacy.body_md.present?
          ContentEditing::BodySynchronizer.new(content).import_markdown!(legacy.body_md)
        elsif legacy.body_html.present?
          ContentEditing::BodySynchronizer.new(content).import_lexxy!(legacy.body_html)
        end
      end

      def legacy_body_present?
        legacy = node.content
        legacy.present? && (legacy.body.present? || legacy.body_md.present? || legacy.body_html.present?)
      end
  end
end
