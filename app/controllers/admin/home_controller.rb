module Admin
  class HomeController < BaseController
    dashboard_section :dashboard, only: :dashboard
    dashboard_section :pages, only: :elenco_pagine
    dashboard_section :didactic_path, only: :percorso_insegnanti

    before_action :require_superadmin!, only: [:elenco_pagine, :percorso_insegnanti, :set_override]

    def percorso_insegnanti
      sheets_root = PosturacorrettaSemeController::GUIDED_ACTIVITIES_ROOT
      @didactic_sources = [
        {
          title: "Sezioni e corsi",
          description: "Indice generale del percorso educativo con sezioni, corsi, ordine e presentazione.",
          path: "posturacorretta_titoli_sezioni_e_corsi.yml",
          kind: "YAML catalogo"
        },
        {
          title: "Corsi online",
          description: "Moduli e capitoli consultabili nei corsi online.",
          path: "posturacorretta_percorso.yml",
          kind: "YAML contenuti"
        },
        {
          title: "Indice del percorso guidato",
          description: "Ordine dei corsi e riferimenti alle attività guidate.",
          path: "posturacorretta_percorso_guidato.yml",
          kind: "YAML generale"
        },
        {
          title: "Insegnanti e abilitazioni",
          description: "Insegnanti pubblici, candidati, corsi autorizzati, livelli e possibilità di supervisione.",
          path: "teachers.yml",
          kind: "YAML persone"
        }
      ]
      @didactic_sources.concat(
        sheets_root.glob("*.{yml,yaml}").sort.map do |path|
          data = YAML.safe_load_file(path, permitted_classes: [], aliases: false)
          {
            title: data["title"].presence || path.basename(path.extname).to_s.humanize,
            description: data["description"].presence || "Attività del percorso guidato.",
            path: "attivita_percorso_guidato/#{path.basename}",
            kind: data["type"] == "lesson" ? "Lezione" : "Incontro"
          }
        end
      )
    end

    def dashboard
      @creator_worlds = RoleAssignment.creator_of_worlds.order(:id)
      @total_nodes = Node.count
      @total_contents = NodeContent.count
      @total_domains = Domain.count
      @domains = Domain.order(:hostname)
      @sample_creator_world = @creator_worlds.first
      @sample_public_node = Node.published_public.order(:id).first
    end

    def set_override
      session[:override_domain_id] = params[:domain_id].presence
      redirect_target = params[:redirect_to].to_s
      if redirect_target.start_with?("/") && !redirect_target.start_with?("//")
        redirect_to redirect_target, notice: "Sito selezionato."
      else
        redirect_back fallback_location: admin_dashboard_path, notice: "Simulazione dominio aggiornata."
      end
    end

    def elenco_pagine
      @registered_pages = Demo::ViewPagesController::PAGES
      @html_files = Dir.children(Rails.root.join("public", "viste_html")).select { |file| file.ends_with?(".html") }.sort
    end
  end
end
