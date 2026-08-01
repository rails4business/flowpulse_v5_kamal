class PosturacorrettaController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :load_academy_curriculum, only: :accademia
  before_action :load_methodologies, only: %i[metodiche metodica]
  before_action :load_projects, only: %i[progetti progetto]
  before_action :load_catalog, only: %i[contenuti articolo]

  def accademia; end
  def percorso
    data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/percorso/percorso.yml"), permitted_classes: [], aliases: false) || {}
    @paths = data.fetch("paths", {})
    @color_classes = data.fetch("colorClasses", {})
    @path_teams = data.fetch("pathTeams", {})
    @path_professionals = data.fetch("pathProfessionals", {})

    taxonomies = PosturacorrettaTaxonomies.load
    @scopes = taxonomies.fetch("scopes", {})
    @areas = taxonomies.fetch("areas", {})

    aside_data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/percorso/aside.yml"), permitted_classes: [], aliases: false) || {}
    @aside_items = aside_data.fetch("items", [])
    professional_group = @aside_items.find { |item| item["type"] == "group" && item["title"] == "Professionisti" }
    @professional_page_slugs = collect_aside_slugs(professional_group&.fetch("children", []) || [])

    requested_slug = params[:page].presence || "inizia"
    @current_item = find_aside_item(@aside_items, requested_slug) || find_aside_item(@aside_items, "inizia")

    if @current_item
      if @current_item["type"] == "markdown"
        md_path = Rails.root.join("config/data", @current_item["source"])
        @page_content = File.exist?(md_path) ? File.read(md_path) : "Contenuto non trovato."
      else
        @page_partial = @current_item["source"]
      end
    end
  end
  def professionisti
    data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/professionisti/professionisti.yml"), permitted_classes: [], aliases: false) || {}
    @professional_scopes = data.fetch("professional_scopes", {})
    @professional_categories = data.fetch("professional_categories", {})
    @professionals = data.fetch("professionals", [])
    redirect_to posturacorretta_percorso_path
  end
  def metodiche; end
  def metodica
    @methodology = @methodologies_by_slug[params.fetch(:slug)]
    return redirect_to posturacorretta_metodiche_path, alert: "Metodica non trovata" unless @methodology
  end
  def contenuti; end
  def articolo
    @article = nil
    @category_key = nil
    @catalog.each do |cat_key, category|
      found = category[:articles].find { |a| a[:slug] == params[:slug] }
      if found
        @article = found
        @category_key = cat_key
        break
      end
    end
    return redirect_to posturacorretta_contenuti_path, alert: "Articolo non trovato" unless @article

    markdown_file = Rails.root.join("config/data/posturacorretta/contenuti/articoli", "#{params[:slug]}.md")
    @content = File.exist?(markdown_file) ? File.read(markdown_file) : nil
  end
  def eventi
    data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/eventi/eventi.yml"), permitted_classes: [], aliases: false) || {}
    @events = data.fetch("events", [])
    @places = data.fetch("places", [])
    @teachers = data.fetch("teachers", [])
  end
  def libro; end
  def progetti
    root = Rails.root.join("config/data/posturacorretta/progetti")
    @page_data = YAML.safe_load_file(root.join("page.yml"), permitted_classes: [], aliases: false) || {}
  end
  def progetto
    @project = @projects.find { |project| project["slug"] == params[:slug] }
    return redirect_to posturacorretta_progetti_path, alert: "Progetto non trovato" unless @project

    requested_tab = %w[overview phases activities].include?(params[:tab]) ? params[:tab] : "overview"
    requested_tab = "phases" if %w[progress realization].include?(params[:tab])
    @project_tab = @project["generaimpresa_origin"] == "historical_import" ? "overview" : requested_tab
    requested_phase = params[:tab] == "realization" ? "implementation" : params[:phase]
    @project_phase = %w[planning funding implementation testing launch repayment].include?(requested_phase) ? requested_phase : "planning"
    @activity_status = %w[upcoming completed cancelled].include?(params[:activity_status]) ? params[:activity_status] : nil
    @data_commitments = if @project["generaimpresa_origin"] == "generaimpresa"
      Brands::Impegno::Commitment.for_genera_impresa_project(@project.fetch("slug")).order(:starts_at)
    else
      Brands::Impegno::Commitment.none
    end
  end
  def collabora; end
  def collabora_professionisti; end
  def collabora_professionisti_guida
    if params[:slug] == "percorso-integrato"
      return redirect_to posturacorretta_percorso_path(page: "professionisti-percorso-integrato")
    end

    root = Rails.root.join("config/data/posturacorretta/collabora/professionisti")
    data = YAML.safe_load_file(root.join("guide.yml"), permitted_classes: [], aliases: false) || {}
    @collaboration_guides = data.fetch("guides", [])
    @collaboration_guide = @collaboration_guides.find { |guide| guide["slug"] == params[:slug] }
    return redirect_to posturacorretta_collabora_professionisti_path, alert: "Approfondimento non trovato" unless @collaboration_guide

    content_path = root.join(@collaboration_guide.fetch("source")).cleanpath
    unless content_path.to_s.start_with?(root.to_s) && content_path.file?
      return redirect_to posturacorretta_collabora_professionisti_path, alert: "Contenuto non disponibile"
    end

    @collaboration_content = content_path.read
  end
  def collabora_digital
    load_projects
    @freelance_tasks = []

    @projects.each do |project|
      %w[planning_activities funding_activities operational_activities].each do |phase|
        activities = project[phase] || []
        activities.each do |activity|
          if activity["delega"] == true && activity["status"] == "pending"
            @freelance_tasks << {
              project_name: project["name"],
              project_slug: project["slug"],
              title: activity["title"],
              type: activity["type"],
              budget: activity["budget"],
              deadline: activity["deadline"],
              notes: activity["notes"]
            }
          end
        end
      end
    end
  end

  private

  def collect_aside_slugs(items)
    items.flat_map do |item|
      [item["slug"], *collect_aside_slugs(item.fetch("children", []))].compact
    end
  end

  def find_aside_item(items, slug)
    items.each do |item|
      return item if item["slug"] == slug
      if item["children"].present?
        found = find_aside_item(item["children"], slug)
        return found if found
      end
    end
    nil
  end

  def load_catalog
    catalog_path = Rails.root.join("config/data/posturacorretta/contenuti/catalog.yml")
    @catalog = File.exist?(catalog_path) ? YAML.safe_load_file(catalog_path, permitted_classes: [], aliases: false, symbolize_names: true) || {} : {}
  end

  def load_projects
    root = Rails.root.join("config/data/posturacorretta/progetti")
    data = PosturacorrettaProjectCatalog.load
    participants_data = YAML.safe_load_file(root.join("progetti_partecipanti.yml"), permitted_classes: [], aliases: false) || {}
    @projects = data.fetch("projects", [])
    @project_participants = participants_data.fetch("participants", [])
    @project_participants_by_slug = @project_participants.index_by { |participant| participant.fetch("slug") }
  end

  def load_academy_curriculum
    @academy_curriculum = AcademyCurriculum.load
    @academy_paths = @academy_curriculum.fetch("paths", [])
    @academy_path = @academy_paths.first
    @academy_areas = @academy_path ? @academy_path.fetch("areas", []) : []
    @academy_modules = @academy_areas.flat_map { |area| area.fetch("modules") }
    @academy_modules = @academy_curriculum.fetch("modules") if @academy_modules.empty?
    @academy_teachers = @academy_curriculum.fetch("teachers", {})
    @academy_locations = @academy_curriculum.fetch("locations", {})
  end

  def load_methodologies
    @methodologies_data = PosturacorrettaMethodologies.load
    @methodologies = @methodologies_data.fetch("methodologies")
    @methodologies_by_slug = @methodologies_data.fetch("methodologies_by_slug")
    @methodology_professionals = @methodologies_data.fetch("professionals")
    @methodology_schools = @methodologies_data.fetch("schools")
  end
end
