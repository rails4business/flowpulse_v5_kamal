module Admin
  class DidacticSourcesController < BaseController
    dashboard_section :didactic_path
    before_action :require_superadmin!

    ROOT = Rails.root.join("config/data/posturacorretta").cleanpath.freeze
    ACADEMY_ROOT = ROOT.join("accademia").cleanpath.freeze
    GENERAL_SOURCE = "posturacorretta_percorso_guidato.yml"
    SHEETS_PREFIX = "attivita_percorso_guidato/"
    CURRENT_SOURCES = %w[
      contenuti/percorso.yml
      contenuti/contents.yml
      programmi/programma_lezioni_posturacorretta.yml
      programmi/calendario_lezioni_gruppo.yml
    ].freeze

    def show
      @relative_path = params[:path].to_s
      @source_path = safe_source_path(@relative_path)
      raise ActionController::RoutingError, "Fonte didattica non trovata" unless @source_path&.file?

      @source_content = @source_path.read
      parsed = YAML.safe_load(@source_content, permitted_classes: [], aliases: false)
      @source_title = parsed.is_a?(Hash) && parsed["title"].present? ? parsed.fetch("title") : @source_path.basename(@source_path.extname).to_s.humanize
      render :show, formats: [:html]
    rescue Psych::Exception
      raise ActionController::RoutingError, "Fonte didattica non valida"
    end

    private

    def safe_source_path(relative_path)
      return unless allowed_relative_path?(relative_path)

      candidate = if CURRENT_SOURCES.include?(relative_path)
        ROOT.join(relative_path).cleanpath
      else
        ACADEMY_ROOT.join(relative_path).cleanpath
      end
      return unless candidate.to_s.start_with?("#{ROOT}/")
      return unless candidate.extname.in?([".yml", ".yaml"])

      candidate
    end

    def allowed_relative_path?(relative_path)
      CURRENT_SOURCES.include?(relative_path) || relative_path == GENERAL_SOURCE || relative_path.start_with?(SHEETS_PREFIX)
    end
  end
end
