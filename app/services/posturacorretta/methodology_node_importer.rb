require "digest"

module Posturacorretta
  class MethodologyNodeImporter
    Result = Data.define(:nodes, :contents)

    CATALOG_PATH = Rails.root.join("config/data/posturacorretta/metodiche/metodiche.yml")
    CONTENT_ROOT = Rails.root.join("config/data/posturacorretta/metodiche")

    def initialize(catalog_path: CATALOG_PATH, content_root: CONTENT_ROOT)
      @catalog_path = Pathname(catalog_path)
      @content_root = Pathname(content_root)
    end

    def import!
      methodologies = YAML.safe_load_file(catalog_path).fetch("methodologies")
      imported_contents = 0

      ActiveRecord::Base.transaction do
        methodologies.each do |methodology|
          node = Node.find_by!(slug: methodology.fetch("slug"))
          validate_node!(node)

          markdown_path = resolved_content_path(methodology.fetch("content_path"))
          markdown = markdown_path.read
          data = { "methodology" => methodology.deep_stringify_keys }

          content = node.content || node.build_content
          content.assign_attributes(
            editor: "markdown",
            format: "markdown",
            body_md: markdown,
            body_html: nil,
            body_json: {},
            data: data,
            source_path: markdown_path.relative_path_from(Rails.root).to_s,
            source_checksum: Digest::SHA256.hexdigest([markdown, data.to_json].join("\n"))
          )
          content.save!
          imported_contents += 1
        end
      end

      Result.new(nodes: methodologies.size, contents: imported_contents)
    end

    private

      attr_reader :catalog_path, :content_root

      def validate_node!(node)
        return if node.parent&.slug == "metodiche-posturali" && node.view_type == "methodology"

        raise ArgumentError, "Node #{node.slug}: gerarchia o view_type della metodica non validi"
      end

      def resolved_content_path(relative_path)
        path = content_root.join(relative_path).cleanpath
        root = content_root.realpath
        resolved = path.realpath
        unless resolved.to_s.start_with?("#{root}#{File::SEPARATOR}")
          raise ArgumentError, "Percorso contenuto metodica non valido: #{relative_path}"
        end

        resolved
      end
  end
end
