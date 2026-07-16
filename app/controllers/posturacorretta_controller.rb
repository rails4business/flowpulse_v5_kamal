class PosturacorrettaController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :load_academy_curriculum, only: :accademia
  before_action :load_methodologies, only: %i[metodiche metodica]

  def accademia; end
  def percorso
    data = YAML.safe_load_file(Rails.root.join("config/data/posturacorretta/percorso/percorso.yml"), permitted_classes: [], aliases: false) || {}
    @paths = data.fetch("paths", {})
    @color_classes = data.fetch("colorClasses", {})
    @path_teams = data.fetch("pathTeams", {})
    @path_professionals = data.fetch("pathProfessionals", {})
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
  def filosofia; end
  def progetti
    render :collabora
  end
  def collabora
    redirect_to posturacorretta_progetti_path
  end

  private

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
