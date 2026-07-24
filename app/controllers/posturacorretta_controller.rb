class PosturacorrettaController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :load_academy_curriculum, only: :accademia
  before_action :load_methodologies, only: %i[metodiche metodica]
  before_action :load_projects, only: %i[progetti progetto]

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

    @project_tab = %w[overview realization activities].include?(params[:tab]) ? params[:tab] : "overview"
    @activity_status = %w[upcoming completed cancelled].include?(params[:activity_status]) ? params[:activity_status] : nil
  end
  def collabora
    redirect_to posturacorretta_progetti_path
  end

  private

  def load_projects
    root = Rails.root.join("config/data/posturacorretta/progetti")
    data = YAML.safe_load_file(root.join("projects.yml"), permitted_classes: [], aliases: false) || {}
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
