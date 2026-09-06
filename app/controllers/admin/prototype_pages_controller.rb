module Admin
  class PrototypePagesController < BaseController
    before_action :require_superadmin!

    PROTOTYPES_ROOT = Rails.root.join("docs/private_prototypes").freeze
    PROGRAM_PREVIEW_PATH = "viste_html/home_posturacorretta_programma.html".freeze
    STUDENT_LESSONS_PATH = Rails.root.join("config/data/posturacorretta/accademia/programma_studenti_lezioni.yml").freeze
    PRACTICAL_SHEETS_ROOT = Rails.root.join("config/data/posturacorretta/accademia/schede_pratiche").freeze

    def show
      return render_program_preview if params[:path] == PROGRAM_PREVIEW_PATH

      root = PROTOTYPES_ROOT.realpath
      file = root.join(params[:path].to_s).cleanpath

      return head :not_found unless file.file? && file.to_s.start_with?("#{root}/")

      send_file file, disposition: "inline", type: Rack::Mime.mime_type(file.extname, "text/plain")
    end

    private

    def render_program_preview
      program = YAML.safe_load_file(STUDENT_LESSONS_PATH, permitted_classes: [], aliases: false).fetch("programma")
      @program_title = program.fetch("title")
      @program_lessons = program.fetch("lessons").map do |lesson|
        sheets = lesson.fetch("sheets", {}).filter_map do |section, reference|
          relative_path = reference.fetch("file")
          sheet_path = PRACTICAL_SHEETS_ROOT.join(relative_path).cleanpath
          next unless sheet_path.file? && sheet_path.to_s.start_with?("#{PRACTICAL_SHEETS_ROOT}/")

          sheet = YAML.safe_load_file(sheet_path, permitted_classes: [], aliases: false)
          next unless sheet.is_a?(Hash)

          sheet.merge("section" => section, "file" => relative_path)
        end

        lesson.merge("sheets" => sheets)
      end

      render :programma_lezioni, layout: false
    end
  end
end
