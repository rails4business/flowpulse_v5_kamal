module Admin
  class NotesController < BaseController
    dashboard_section :notes
    before_action :require_superadmin!

    DOCUMENTATION_SOURCES = {
      "docs" => Rails.root.join("docs"),
      "workspace" => Rails.root
    }.freeze

    def index
      @notes_by_source = DOCUMENTATION_SOURCES.to_h do |source, root|
        [source, documentation_entries(source, root)]
      end
    end

    def show
      @source = params[:source].to_s
      root = DOCUMENTATION_SOURCES.fetch(@source) { raise ActionController::RoutingError, "Appunti non trovati" }
      @relative_path = params[:path].to_s
      @note_path = safe_note_path(root, @relative_path)
      raise ActionController::RoutingError, "Appunto non trovato" unless @note_path&.file? && @note_path.extname == ".md"

      @note_title = document_title(@note_path)
      @note_content = @note_path.read
    end

    private

    def documentation_entries(source, root)
      paths = if source == "workspace"
        root.children.select { |path| path.file? && path.extname == ".md" }
      else
        root.glob("**/*.md")
      end

      paths.sort_by { |path| path.relative_path_from(root).to_s }.map do |path|
        relative_path = path.relative_path_from(root).to_s
        {
          path: relative_path,
          folder: File.dirname(relative_path) == "." ? "Generali" : File.dirname(relative_path),
          title: document_title(path)
        }
      end
    end

    def safe_note_path(root, relative_path)
      return if relative_path.blank?

      candidate = root.join(relative_path).cleanpath
      root_prefix = "#{root}/"
      return unless candidate.to_s.start_with?(root_prefix)

      candidate
    end

    def document_title(path)
      heading = path.foreach.lazy.map(&:strip).find { |line| line.start_with?("# ") }
      heading&.delete_prefix("# ")&.presence || path.basename(".md").to_s.tr("-_", " ").titleize
    end
  end
end
