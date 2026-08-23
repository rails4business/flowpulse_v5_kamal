class PosturacorrettaSemeController < ApplicationController
  layout "landing"
  allow_unauthenticated_access

  GUIDE_INDEX_PATH = Rails.root.join("config/data/posturacorretta/guide/indice.yml").freeze
  ACADEMY_PATH = Rails.root.join("config/data/posturacorretta/accademia/academy.yml").freeze
  CONTENT_ROOT = Rails.root.join("config/data/posturacorretta").cleanpath.freeze
  ADVANCED_SEPARATOR = /\n<!--\s*advanced\s*-->\s*\n/i

  def show
    load_curriculum_sources
    @courses = build_courses

    if params[:lesson].blank? && params[:stage].present?
      return load_course_index
    end

    return unless params[:lesson].present?

    load_selected_lesson
  end

  def percorso
    load_curriculum_sources
    @courses = build_courses
    @direct_courses = [@courses.first, build_postura_fisiologia_course]
    @recovery_courses = @courses.drop(1)
    render :show
  end

  def dashboard_student
    load_dashboard_data
    @dashboard_kind = "student"
    render :show
  end

  def dashboard_teacher
    load_dashboard_data
    @dashboard_kind = "teacher"
    @teacher_access = Current.user&.teacher_user? || Current.user&.superadmin_user? || false
    render :show
  end

  private

  def load_curriculum_sources
    guide_data = YAML.safe_load_file(GUIDE_INDEX_PATH, permitted_classes: [], aliases: false)
    academy_data = YAML.safe_load_file(ACADEMY_PATH, permitted_classes: [], aliases: false)
    first_month = guide_data.fetch("sections").find { |section| section.fetch("id") == "primo_mese" }

    @base_stage = {
      "number" => "01",
      "slug" => "primo-mese",
      "title" => first_month.fetch("title"),
      "description" => "Introduzione al metodo, prima osservazione del corpo e prima applicazione pratica.",
      "lessons" => first_month.fetch("items").filter_map do |item|
        next unless item.fetch("type") == "markdown"

        {
          "slug" => item.fetch("slug"),
          "title" => item.fetch("title"),
          "content_path" => item.fetch("source")
        }
      end
    }

    @academy_stage = {
      "number" => "02",
      "slug" => "accademia",
      "title" => "Accademia PosturaCorretta",
      "description" => academy_data.dig("paths", 0, "description"),
      "modules" => academy_data.fetch("modules").map do |mod|
        mod.merge(
          "lessons" => mod.fetch("lessons").map do |lesson|
            next lesson unless lesson["content_path"].present?

            lesson.merge("content_path" => File.join("accademia", lesson.fetch("content_path")))
          end
        )
      end
    }
    @stages = [@base_stage, @academy_stage]
  end

  def build_courses
    base_course = {
      "number" => "01",
      "stage" => @base_stage.fetch("slug"),
      "slug" => @base_stage.fetch("slug"),
      "title" => @base_stage.fetch("title"),
      "description" => @base_stage.fetch("description"),
      "lessons" => @base_stage.fetch("lessons"),
      "level" => "base"
    }

    academy_courses = @academy_stage.fetch("modules").each_with_index.map do |mod, index|
      mod.merge(
        "number" => format("%02d", index + 2),
        "stage" => @academy_stage.fetch("slug"),
        "level" => "base_advanced"
      )
    end

    [base_course, *academy_courses]
  end

  def build_postura_fisiologia_course
    {
      "number" => "02",
      "slug" => "postura-e-fisiologia",
      "title" => "Postura e Fisiologia",
      "description" => "Le cinque aree della salute spiegate attraverso postura, fisiologia e relazioni tra i sistemi del corpo.",
      "lessons" => [],
      "status" => "draft"
    }
  end

  def load_dashboard_data
    load_curriculum_sources
    @courses = build_courses
    @lesson_count = @courses.sum { |course| course.fetch("lessons").size }
    @selected_participation = params[:participation].presence_in(%w[autonomy group individual])
  end

  def load_selected_lesson
    stage_slug = params[:stage].presence_in(@stages.map { |stage| stage.fetch("slug") }) || "primo-mese"
    @selected_stage = @stages.find { |stage| stage.fetch("slug") == stage_slug }

    if stage_slug == "primo-mese"
      @selected_course = @courses.first
    else
      module_slug = params[:module].presence
      @selected_course = @courses.find { |course| course["stage"] == "accademia" && course.fetch("slug") == module_slug }
    end

    return redirect_to(posturacorretta_seme_path, alert: "Corso non trovato") unless @selected_course

    @course_lessons = @selected_course.fetch("lessons")
    @lesson = @course_lessons.find { |lesson| lesson.fetch("slug") == params[:lesson] }
    return redirect_to(posturacorretta_seme_path, alert: "Lezione non trovata") unless @lesson

    load_lesson_content
  end

  def load_course_index
    stage_slug = params[:stage].presence_in(@stages.map { |stage| stage.fetch("slug") }) || "primo-mese"
    @selected_stage = @stages.find { |stage| stage.fetch("slug") == stage_slug }
    @selected_course = if stage_slug == "primo-mese"
      @courses.first
    else
      @courses.find { |course| course["stage"] == "accademia" && course.fetch("slug") == params[:module] }
    end

    return redirect_to(posturacorretta_seme_percorso_path, alert: "Corso non trovato") unless @selected_course

    @course_lessons = @selected_course.fetch("lessons")
  end

  def load_lesson_content
    content_path = @lesson["content_path"]
    @base_content = ""
    @advanced_content = nil
    @advanced_defined = false
    @advanced_access = Current.user&.superadmin_user? || false
    return if content_path.blank?

    lesson_path = CONTENT_ROOT.join(content_path).cleanpath
    return unless lesson_path.to_s.start_with?(CONTENT_ROOT.to_s) && lesson_path.file?

    base, advanced = lesson_path.read.split(ADVANCED_SEPARATOR, 2)
    @base_content = base.to_s
    @advanced_defined = advanced.present?
    @advanced_content = advanced if @advanced_access && @advanced_defined
  end
end
