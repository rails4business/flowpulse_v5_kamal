class PosturacorrettaSemeController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :require_authentication, only: [:dashboard_student, :dashboard_appointments, :dashboard_teacher]

  GUIDE_INDEX_PATH = Rails.root.join("config/data/posturacorretta/guide/indice.yml").freeze
  ACADEMY_PATH = Rails.root.join("config/data/posturacorretta/accademia/academy.yml").freeze
  DIDACTIC_PATH = Rails.root.join("config/data/posturacorretta/accademia/posturacorretta_titoli_sezioni_e_corsi.yml").freeze
  GUIDED_PATH = Rails.root.join("config/data/posturacorretta/accademia/posturacorretta_percorso_guidato.yml").freeze
  LESSON_PROGRAM_PATH = Rails.root.join("config/data/posturacorretta/accademia/programma_lezioni_posturacorretta.yml").freeze
  SCHEDULED_LESSONS_PATH = Rails.root.join("config/data/posturacorretta/accademia/lezioni_programmate.yml").freeze
  GUIDED_ACTIVITIES_ROOT = Rails.root.join("config/data/posturacorretta/accademia/attivita_percorso_guidato").freeze
  LEARNING_PATH = Rails.root.join("config/data/posturacorretta/accademia/posturacorretta_percorso.yml").freeze
  CONTENT_ROOT = Rails.root.join("config/data/posturacorretta").cleanpath.freeze
  ADVANCED_SEPARATOR = /\n<!--\s*advanced\s*-->\s*\n/i

  def index
    load_curriculum_sources
    @courses = build_courses
    @direct_courses = @didactic_courses
    render :show
  end

  def programma
    load_curriculum_sources
    @courses = build_courses
    load_lesson_meetings
    return if performed?

    if params[:attivita].blank?
      return redirect_to posturacorretta_course_path(corso: @learning_course.fetch("slug"), vista: "incontri")
    end
    render :show
  end

  def course
    load_curriculum_sources
    course_slug = params[:corso].presence_in(@all_didactic_courses.map { |item| item.fetch("slug") })
    return redirect_to(posturacorretta_path, alert: "Corso non trovato") unless course_slug

    load_course_overview(course_slug)
    render :show
  end

  def legacy_programma
    course_slug = params[:corso].presence || "postura-corretta-in-un-mese"
    destination = if params[:attivita].present?
      posturacorretta_course_lesson_path(corso: course_slug, attivita: params[:attivita])
    else
      posturacorretta_course_lessons_path(corso: course_slug)
    end
    redirect_to destination, status: :moved_permanently
  end

  def legacy_percorso_educativo
    course_slug = params[:corso].presence || "postura-corretta-in-un-mese"
    destination = if params[:capitolo].present?
      posturacorretta_course_chapter_path(corso: course_slug, capitolo: params[:capitolo])
    else
      posturacorretta_course_chapters_path(corso: course_slug)
    end
    redirect_to destination, status: :moved_permanently
  end

  def percorso_educativo
    load_curriculum_sources
    @courses = build_courses
    load_learning_course
    if params[:capitolo].blank?
      return redirect_to posturacorretta_course_path(corso: @reader_course_slug, vista: "capitoli")
    end
    render :show
  end

  def show
    if params[:sezione].present? || params[:capitolo].present? || params[:chapter].present?
      section = params[:sezione].presence || legacy_section_for(params[:chapter])
      chapter = params[:capitolo].presence || params[:chapter]
      return redirect_to posturacorretta_guida_path(sezione: section, capitolo: chapter), status: :moved_permanently
    end

    load_curriculum_sources
    return redirect_legacy_learning_path if params[:stage].present? || params[:lesson].present?

    redirect_to posturacorretta_path, status: :moved_permanently
  end

  def percorso
    redirect_to posturacorretta_path, status: :moved_permanently
  end

  def integrated_paths
    load_curriculum_sources
    @courses = build_courses
    @integrated_paths_page = true
    render :show
  end

  def dashboard_student
    ensure_current_user_site_access!(authentication_context_domain) if authentication_context?
    return redirect_to(posturacorretta_student_appointments_path) if params[:vista] == "calendario"

    load_dashboard_data
    @dashboard_kind = "student"
    render :show
  end

  def dashboard_appointments
    ensure_current_user_site_access!(authentication_context_domain) if authentication_context?
    load_dashboard_data(view: "calendario")
    @dashboard_kind = "student"
    render :show
  end

  def dashboard_teacher
    ensure_current_user_site_access!(authentication_context_domain) if authentication_context?
    load_dashboard_data
    @dashboard_kind = "teacher"
    @teacher_access = Current.user&.teacher_user? || Current.user&.superadmin_user? || false
    render :show
  end

  private

  def legacy_section_for(chapter)
    chapter.to_s.match?(/\A(?:07|08|09|10|11)-/) ? "progetto" : "primo_mese"
  end

  def load_curriculum_sources
    guide_data = YAML.safe_load_file(GUIDE_INDEX_PATH, permitted_classes: [], aliases: false)
    academy_data = YAML.safe_load_file(ACADEMY_PATH, permitted_classes: [], aliases: false)
    didactic_data = YAML.safe_load_file(DIDACTIC_PATH, permitted_classes: [], aliases: false)
    learning_data = YAML.safe_load_file(LEARNING_PATH, permitted_classes: [], aliases: false)
    program_data = YAML.safe_load_file(GUIDED_PATH, permitted_classes: [], aliases: false)
    @program_by_course = hydrate_program_courses(program_data).index_by { |course| course.fetch("course_slug") }
    @program_course_slugs = @program_by_course.keys
    learning_by_course = learning_data.fetch("courses").index_by { |course| course.fetch("course_slug") }
    @didactic_path = didactic_data.fetch("path")
    @didactic_courses = @didactic_path.fetch("courses").map { |course| decorate_didactic_course(course, learning_by_course) }
    @didactic_sections = @didactic_path.fetch("sections", []).map do |section|
      section.merge(
        "courses" => section.fetch("courses", []).map { |course| decorate_didactic_course(course, learning_by_course) }
      )
    end
    section_courses = @didactic_sections.flat_map do |section|
      section.fetch("courses", []).map do |course|
        course.merge(
          "section_slug" => section.fetch("slug"),
          "level" => course["level"] || section.fetch("level", "base"),
          "description" => course["description"] || section.fetch("description")
        )
      end
    end
    @all_didactic_courses = @didactic_courses + section_courses
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

  def load_lesson_meetings
    data = YAML.safe_load_file(GUIDED_PATH, permitted_classes: [], aliases: false)
    @lesson_delivery_by_course = hydrate_program_courses(data).index_by { |course| course.fetch("course_slug") }
    @home_program_courses = @all_didactic_courses
    requested_course = (params[:corso].presence || params[:programma].presence).presence_in(@home_program_courses.map { |course| course.fetch("slug") })
    @learning_course = @home_program_courses.find { |course| course.fetch("slug") == requested_course } || @home_program_courses.first
    @learning_course_index = @home_program_courses.index(@learning_course)
    @previous_learning_course = @home_program_courses[@learning_course_index - 1] if @learning_course_index.positive?
    @next_learning_course = @home_program_courses[@learning_course_index + 1]

    delivery = @lesson_delivery_by_course.fetch(@learning_course.fetch("slug"), { "program" => [] })
    @learning_program_steps = decorate_program_steps(delivery.fetch("program", [])).map { |activity| activity.merge("source_type" => "program_item") }
    @lesson_delivery_by_course[@learning_course.fetch("slug")] = delivery.merge("program" => @learning_program_steps)

    requested_activity = params[:attivita].presence_in(@learning_program_steps.map { |step| step.fetch("slug") })
    @selected_program_step = @learning_program_steps.find { |step| step.fetch("slug") == requested_activity } || @learning_program_steps.first
    available_levels = @selected_program_step&.fetch("levels", {})&.keys || []
    @selected_program_level = params[:livello].presence_in(available_levels) || available_levels.first
    participation = @selected_program_step&.fetch("participation", {}) || {}
    @available_participation_roles = participation.fetch("roles", {}).select { |_role, details| details.fetch("enabled", true) }
    default_participation_role = participation["default_role"].presence_in(@available_participation_roles.keys) || @available_participation_roles.keys.first
    @selected_participation_role = params[:ruolo].presence_in(@available_participation_roles.keys) || default_participation_role
    @selected_participation_label = @available_participation_roles.dig(@selected_participation_role, "label")
    internship = @available_participation_roles.dig(@selected_participation_role, "internship") || {}
    @available_internship_modes = internship.fetch("modes", {})
    default_internship_mode = internship["default_mode"].presence_in(@available_internship_modes.keys) || @available_internship_modes.keys.first
    @selected_internship_mode = params[:tirocinio].presence_in(@available_internship_modes.keys) || default_internship_mode
    @selected_internship_details = @available_internship_modes[@selected_internship_mode]
    @internship_supervisor_required = internship.fetch("supervisor_required", false)

    if @selected_program_step&.fetch("progress_state", nil) == "locked"
      available_step = @learning_program_steps.find { |step| step.fetch("progress_state") == "available" }
      return redirect_to(
        posturacorretta_course_lesson_path(corso: @learning_course.fetch("slug"), attivita: available_step.fetch("slug")),
        alert: "Completa prima l’attività precedente."
      ) if available_step
    end

  end

  def load_course_overview(course_slug)
    program_data = YAML.safe_load_file(GUIDED_PATH, permitted_classes: [], aliases: false)
    program_by_course = hydrate_program_courses(program_data).index_by { |course| course.fetch("course_slug") }
    didactic_course = @all_didactic_courses.find { |course| course.fetch("slug") == course_slug }

    @course_overview = true
    @course_overview_tab = params[:vista].presence_in(%w[incontri capitoli]) || "incontri"
    @reader_course_slug = course_slug
    @selected_course = didactic_course
    @course_program_steps = decorate_program_steps(program_by_course.fetch(course_slug, { "program" => [] }).fetch("program", []))
    selected_activity_slug = params[:attivita].presence_in(@course_program_steps.map { |step| step.fetch("slug") })
    @selected_course_program_step = @course_program_steps.find { |step| step.fetch("slug") == selected_activity_slug } ||
      @course_program_steps.find { |step| step.fetch("progress_state") == "available" } ||
      @course_program_steps.first
    @course_lessons = didactic_course.fetch("chapters", []).map { |chapter| learning_lesson(chapter) }
  end

  def decorate_program_steps(steps)
    completed = steps.map do |step|
      step.fetch("participations", []).any? { |participation| participation["date"].present? }
    end
    first_incomplete_index = completed.index(false)

    steps.each_with_index.map do |step, index|
      progress_state = if completed[index]
        "completed"
      elsif index == first_incomplete_index
        "available"
      else
        "locked"
      end

      step.merge("progress_state" => progress_state)
    end
  end

  def hydrate_program_courses(data)
    data.fetch("courses").map do |course|
      activities = course.fetch("activities", course.fetch("program", []))
      course.except("activities").merge("program" => activities.map { |step| hydrate_program_step(step) })
    end
  end

  def decorate_didactic_course(course, learning_by_course)
    learning_course = learning_by_course.fetch(course.fetch("slug"), {})
    modules = learning_course.fetch("modules", [])
    chapters = if modules.present?
      modules.flat_map do |mod|
        mod.fetch("chapters", []).map do |chapter|
          chapter.merge("module_slug" => mod.fetch("slug"), "module_title" => mod.fetch("title"))
        end
      end
    else
      learning_course.fetch("chapters", [])
    end

    course.merge("modules" => modules, "chapters" => chapters)
  end

  def hydrate_program_step(step)
    return step unless step["source"].present?

    source_path = GUIDED_ACTIVITIES_ROOT.join(step.fetch("source")).cleanpath
    root_prefix = "#{GUIDED_ACTIVITIES_ROOT.cleanpath}/"
    unless source_path.to_s.start_with?(root_prefix) && source_path.file? && source_path.extname.in?([".yml", ".yaml"])
      raise KeyError, "Scheda del programma non trovata: #{step.fetch('source')}"
    end

    YAML.safe_load_file(source_path, permitted_classes: [], aliases: false)
      .merge(step.except("source"))
      .merge("source" => step.fetch("source"))
  end

  def load_learning_course
    requested_slug = params[:corso].presence_in(@all_didactic_courses.map { |course| course.fetch("slug") })
    didactic_course = @all_didactic_courses.find { |course| course.fetch("slug") == requested_slug } || @all_didactic_courses.first
    @reader_course_slug = didactic_course.fetch("slug")
    @selected_stage = { "slug" => "percorso-educativo", "title" => @didactic_path.fetch("title") }
    @course_lessons = didactic_course.fetch("chapters", []).map { |chapter| learning_lesson(chapter) }
    @selected_course = didactic_course.merge("lessons" => @course_lessons)

    return if params[:capitolo].blank?

    @lesson = @course_lessons.find { |lesson| lesson.fetch("slug") == params[:capitolo] }
    return redirect_to(posturacorretta_course_chapters_path(corso: @reader_course_slug), alert: "Capitolo non trovato") unless @lesson

    load_lesson_content
  end

  def learning_lesson(chapter)
    legacy_lesson = if chapter["content_stage"] == "primo-mese"
      @base_stage.fetch("lessons").find { |lesson| lesson.fetch("slug") == chapter["content_ref"] }
    elsif chapter["content_stage"] == "accademia"
      mod = @academy_stage.fetch("modules").find { |item| item.fetch("slug") == chapter["content_module"] }
      mod&.fetch("lessons", [])&.find { |lesson| lesson.fetch("slug") == chapter["content_ref"] }
    end

    chapter.merge("content_path" => legacy_lesson&.fetch("content_path", nil) || chapter["content_path"])
  end

  def redirect_legacy_learning_path
    course_slug = params[:stage] == "accademia" ? params[:module] : "postura-corretta-in-un-mese"
    didactic_course = @all_didactic_courses.find { |course| course.fetch("slug") == course_slug } || @all_didactic_courses.first
    legacy_ref = params[:lesson]
    chapter = didactic_course.fetch("chapters", []).find { |item| item["content_ref"] == legacy_ref || item.fetch("slug") == legacy_ref }
    destination = { corso: didactic_course.fetch("slug") }
    destination[:capitolo] = chapter.fetch("slug") if chapter
    redirect_to(destination[:capitolo].present? ? posturacorretta_course_chapter_path(corso: destination.fetch(:corso), capitolo: destination.fetch(:capitolo)) : posturacorretta_course_chapters_path(corso: destination.fetch(:corso)), status: :moved_permanently)
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

  def load_dashboard_data(view: nil)
    load_curriculum_sources
    lesson_program_data = YAML.safe_load_file(LESSON_PROGRAM_PATH, permitted_classes: [], aliases: false)
    lesson_program_by_course = lesson_program_data.fetch("courses").index_by { |course| course.fetch("course_slug") }
    @courses = @all_didactic_courses
    @dashboard_courses = @courses.map do |course|
      configured_program = @program_by_course.fetch(course.fetch("slug"), { "program" => [] }).fetch("program", [])
      program = configured_program.presence || lesson_program_by_course.fetch(course.fetch("slug"), { "program" => [] }).fetch("program", [])
      activities = decorate_program_steps(program)
      course.merge(
        "program" => activities,
        "chapter_count" => course.fetch("chapters", []).size,
        "next_activity" => activities.find { |activity| activity.fetch("progress_state") == "available" }
      )
    end
    @lesson_count = @dashboard_courses.sum { |course| course.fetch("program").size }
    @chapter_count = @dashboard_courses.sum { |course| course.fetch("chapter_count") }
    @starting_course = @dashboard_courses.find { |course| course.fetch("slug") == "postura-corretta-in-un-mese" } || @dashboard_courses.first
    @dashboard_view = view.presence_in(%w[programma calendario]) || params[:vista].presence_in(%w[programma calendario]) || "programma"
    dashboard_courses_by_slug = @dashboard_courses.index_by { |course| course.fetch("slug") }
    @dashboard_sections = []
    @dashboard_sections << {
      "title" => "Corsi iniziali",
      "description" => "Le basi del percorso educativo PosturaCorretta.",
      "courses" => @didactic_courses.filter_map { |course| dashboard_courses_by_slug[course.fetch("slug")] }
    }
    @dashboard_sections.concat(@didactic_sections.map do |section|
      section.slice("slug", "title", "description").merge(
        "courses" => section.fetch("courses", []).filter_map { |course| dashboard_courses_by_slug[course.fetch("slug")] }
      )
    end)
    load_dashboard_agenda
    @selected_participation = params[:participation].presence_in(%w[group individual])
  end

  def load_dashboard_agenda
    schedule_data = YAML.safe_load_file(SCHEDULED_LESSONS_PATH, permitted_classes: [], aliases: false)
    scheduled_lessons = schedule_data.fetch("lessons", []).filter_map do |lesson|
      next unless lesson.fetch("status", "draft") == "published"
      next if lesson["starts_at"].blank?

      starts_at = Time.zone.parse(lesson.fetch("starts_at"))
      next unless starts_at

      {
        source: "scheduled_lesson",
        title: lesson.fetch("title"),
        starts_at: starts_at,
        ends_at: lesson["ends_at"].present? ? Time.zone.parse(lesson.fetch("ends_at")) : nil,
        domain_label: "PosturaCorretta",
        role_label: lesson["audience_role"].to_s.humanize.presence,
        format: lesson["format"],
        delivery: lesson["delivery"],
        location_name: lesson["location_name"],
        teacher_slug: lesson["teacher_slug"],
        status: lesson.fetch("status")
      }
    end

    profile = Current.user.profile
    commitments = if Current.user.superadmin_user?
      DataCommitment.includes(:domain).where.not(status: "cancelled")
    elsif profile
      profile.data_commitments.includes(:domain).where.not(status: "cancelled")
    else
      DataCommitment.none
    end
    commitment_entries = commitments.map do |commitment|
      metadata = commitment.metadata.to_h
      posturacorretta_commitment = commitment.domain&.auth_slug == "posturacorretta" ||
        %w[posturacorretta.org www.posturacorretta.org].include?(commitment.domain&.hostname)
      {
        source: "commitment",
        title: commitment.title,
        starts_at: commitment.starts_at,
        ends_at: commitment.ends_at,
        domain_label: commitment.domain&.site_title.presence || commitment.domain&.hostname || "Flowpulse",
        role_label: metadata["role_context"].presence || metadata["role"].presence,
        format: metadata["format"],
        delivery: commitment.online_url.present? ? "online" : "in_person",
        location_name: commitment.location_name,
        teacher_slug: metadata["teacher_slug"],
        status: commitment.status,
        external_context: !posturacorretta_commitment
      }
    end

    @dashboard_agenda_entries = (scheduled_lessons + commitment_entries).sort_by { |entry| entry.fetch(:starts_at) }
    @dashboard_agenda_upcoming = @dashboard_agenda_entries.select { |entry| entry.fetch(:starts_at) >= Time.current }
    @dashboard_agenda_past = @dashboard_agenda_entries.select { |entry| entry.fetch(:starts_at) < Time.current }.reverse
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
