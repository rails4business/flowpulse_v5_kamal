module Posturacorretta
  class LearningController < ApplicationController
  layout "landing"
  allow_unauthenticated_access
  before_action :require_authentication, only: [:dashboard_appointments, :dashboard_teacher]

  GUIDE_INDEX_PATH = Rails.root.join("config/data/posturacorretta/guide/indice.yml").freeze
  ACADEMY_PATH = Rails.root.join("config/data/posturacorretta/accademia/academy.yml").freeze
  DIDACTIC_PATH = Rails.root.join("config/data/posturacorretta/contenuti/percorso.yml").freeze
  GUIDED_PATH = Rails.root.join("config/data/posturacorretta/accademia/posturacorretta_percorso_guidato.yml").freeze
  LESSON_PROGRAM_PATH = Rails.root.join("config/data/posturacorretta/programmi/programma_lezioni_posturacorretta.yml").freeze
  GROUP_LESSON_CALENDAR_PATH = Rails.root.join("config/data/posturacorretta/programmi/calendario_lezioni_gruppo.yml").freeze
  SCHEDULED_LESSONS_PATH = Rails.root.join("config/data/posturacorretta/accademia/lezioni_programmate.yml").freeze
  PRACTICAL_SHEETS_ROOT = Rails.root.join("config/data/posturacorretta/accademia/schede_pratiche").freeze
  GUIDED_ACTIVITIES_ROOT = Rails.root.join("config/data/posturacorretta/accademia/attivita_percorso_guidato").freeze
  LEARNING_PATH = Rails.root.join("config/data/posturacorretta/accademia/posturacorretta_percorso.yml").freeze
  CONTENT_CATALOG_PATH = Rails.root.join("config/data/posturacorretta/contenuti/contents.yml").freeze
  CONTENT_ROOT = Rails.root.join("config/data/posturacorretta").cleanpath.freeze
  DATA_ROOT = Rails.root.join("config/data").cleanpath.freeze

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
      return redirect_to posturacorretta_course_path(corso: @learning_course.fetch("slug"), vista: "schede")
    end
    render :show
  end

  def course
    if params[:corso] == "postura-corretta-in-un-mese"
      return redirect_to(book_chapter_path(book_slug: "postura-corretta-in-un-mese", id: "copertina"), status: :moved_permanently)
    end

    load_curriculum_sources
    course_slug = params[:corso].presence_in(@all_didactic_courses.map { |item| item.fetch("slug") })
    return redirect_to(posturacorretta_path, alert: "Corso non trovato") unless course_slug
    return redirect_to(posturacorretta_course_path(corso: course_slug), status: :moved_permanently) if params[:vista].present?

    load_course_overview(course_slug)
    return if performed?

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
    if params[:corso] == "postura-corretta-in-un-mese"
      destination = if params[:capitolo].present?
        book_chapter_path(book_slug: "postura-corretta-in-un-mese", id: params[:capitolo])
      else
        book_chapter_path(book_slug: "postura-corretta-in-un-mese", id: "copertina")
      end
      return redirect_to(destination, status: :moved_permanently)
    end

    load_curriculum_sources
    @courses = build_courses
    load_learning_course
    return if performed?

    if params[:capitolo].blank?
      return redirect_to posturacorretta_course_path(corso: @reader_course_slug)
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
    ensure_current_user_site_access!(authentication_context_domain) if authentication_context? && authenticated?
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
    @teacher_access = Current.user&.superadmin_user? ||
      Current.user&.role_assignments&.where(role: :operator, role_operator: "insegnante")&.exists? ||
      false
    render :show
  end

  private

  def legacy_section_for(chapter)
    chapter.to_s.match?(/\A(?:07|08|09|10|11)-/) ? "progetto" : "primo_mese"
  end

  def load_curriculum_sources
    academy_data = YAML.safe_load_file(ACADEMY_PATH, permitted_classes: [], aliases: false)
    didactic_data = YAML.safe_load_file(DIDACTIC_PATH, permitted_classes: [], aliases: false)
    learning_data = YAML.safe_load_file(LEARNING_PATH, permitted_classes: [], aliases: false)
    @content_repository = Posturacorretta::ContentRepository.new(
      path: CONTENT_CATALOG_PATH,
      include_scheduled: true
    )
    calendar_data = YAML.safe_load_file(GROUP_LESSON_CALENDAR_PATH, permitted_classes: [], aliases: false).fetch("calendar")
    group_lesson = (calendar_data["group_lessons"] || [calendar_data.fetch("group_lesson")]).first
    first_release = Time.zone.parse("#{calendar_data.fetch('starts_on')} #{calendar_data.fetch('publication_time')}")
    @course_release_schedule = calendar_data.fetch("courses").each_with_index.to_h do |scheduled_course, index|
      [scheduled_course.fetch("content_id"), first_release + index.weeks]
    end
    @scheduled_courses_by_id = calendar_data.fetch("courses").index_by { |scheduled_course| scheduled_course.fetch("content_id") }
    current_release = @course_release_schedule.select { |_content_id, release_at| release_at <= Time.current }.max_by { |_content_id, release_at| release_at }
    focus_content_id = current_release&.first || calendar_data.fetch("courses").first.fetch("content_id")
    focus_course = @scheduled_courses_by_id.fetch(focus_content_id)
    @home_week_focus = focus_course.merge(
      "release_at" => @course_release_schedule.fetch(focus_content_id).iso8601,
      "locked" => @course_release_schedule.fetch(focus_content_id) > Time.current,
      "lesson_day" => group_lesson.fetch("day"),
      "lesson_start" => group_lesson.fetch("start"),
      "lesson_end" => group_lesson.fetch("end"),
      "lesson_location" => group_lesson.fetch("location")
    )
    program_data = YAML.safe_load_file(GUIDED_PATH, permitted_classes: [], aliases: false)
    @program_by_course = hydrate_program_courses(program_data).index_by { |course| course.fetch("course_slug") }
    @program_course_slugs = @program_by_course.keys
    learning_by_course = learning_data.fetch("courses").index_by { |course| course.fetch("course_slug") }
    @didactic_path = didactic_data.fetch("path")
    @didactic_courses = @didactic_path.fetch("courses").filter_map { |course| decorate_path_course(course, learning_by_course) }
    @didactic_sections = @didactic_path.fetch("sections", []).map do |section|
      section.merge(
      "courses" => section.fetch("courses", []).filter_map { |course| decorate_path_course(course, learning_by_course) }
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
    first_month_book_directory = BrandEditorial::BookLocator.new.find("postura-corretta-in-un-mese")
    first_month_book = YAML.safe_load_file(first_month_book_directory.join("book.yml"), permitted_classes: [], aliases: false) || {}
    first_month_chapters = YAML.safe_load_file(first_month_book_directory.join("index.yml"), permitted_classes: [], aliases: false) || []

    @base_stage = {
      "number" => "01",
      "slug" => "primo-mese",
      "title" => first_month_book.fetch("title"),
      "description" => "Introduzione al metodo, prima osservazione del corpo e prima applicazione pratica.",
      "lessons" => first_month_chapters.map do |item|
        {
          "slug" => item.fetch("slug"),
          "title" => item.fetch("title"),
          "book_chapter_path" => book_chapter_path(book_slug: "postura-corretta-in-un-mese", id: item.fetch("slug"))
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
    legacy_first_month_course = decorate_didactic_course(
      {
        "slug" => "postura-corretta-in-un-mese",
        "title" => first_month_book.fetch("title"),
        "description" => "Archivio interno del precedente corso, mantenuto per il programma lezioni.",
        "status" => "legacy"
      },
      learning_by_course
    )
    @all_didactic_courses = @didactic_courses + section_courses + [legacy_first_month_course]
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
      redirect_to(
        posturacorretta_course_lesson_path(corso: @learning_course.fetch("slug"), attivita: available_step.fetch("slug")),
        alert: "Completa prima l’attività precedente."
      ) if available_step
    end
  end

  def load_course_overview(course_slug)
    didactic_course = @all_didactic_courses.find { |course| course.fetch("slug") == course_slug }
    if didactic_course&.fetch("release_locked", false)
      release_date = Time.zone.parse(didactic_course.fetch("release_at")).to_date
      return redirect_to(posturacorretta_path(anchor: didactic_course.fetch("slug")), alert: "Il corso sarà disponibile dal #{I18n.l(release_date, format: :long)}.")
    end

    @course_overview = true
    @reader_course_slug = course_slug
    @selected_course = didactic_course
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

  def decorate_path_course(course, learning_by_course)
    decorated = if course["content_id"].present?
      @content_repository.course_by_id(course.fetch("content_id")) || scheduled_course_placeholder(course.fetch("content_id"))
    else
      decorate_didactic_course(course, learning_by_course)
    end
    return unless decorated

    release_at = @course_release_schedule[decorated.fetch("id", decorated.fetch("slug"))]
    release_locked = release_at.present? && release_at > Time.current
    chapters = decorated.fetch("chapters", []).map do |chapter|
      chapter.merge("release_at" => release_at&.iso8601, "release_locked" => release_locked && !chapter.fetch("demo", false))
    end
    decorated.merge("release_at" => release_at&.iso8601, "release_locked" => release_locked, "chapters" => chapters)
  end

  def scheduled_course_placeholder(content_id)
    scheduled = @scheduled_courses_by_id[content_id]
    return unless scheduled

    {
      "id" => content_id,
      "slug" => content_id,
      "format" => "course",
      "title" => scheduled.fetch("title"),
      "description" => "Corso in preparazione: sarà pubblicato nella settimana programmata.",
      "status" => "draft",
      "access" => "free",
      "chapters" => []
    }
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
    requested_chapter = didactic_course.fetch("chapters", []).find { |chapter| chapter.fetch("slug") == params[:capitolo] }
    demo_chapter = requested_chapter&.fetch("demo", false)
    if didactic_course.fetch("release_locked", false) && !demo_chapter
      release_date = Time.zone.parse(didactic_course.fetch("release_at")).to_date
      return redirect_to(posturacorretta_path(anchor: didactic_course.fetch("slug")), alert: "Il corso sarà disponibile dal #{I18n.l(release_date, format: :long)}.")
    end
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
    @courses = @all_didactic_courses
    @dashboard_courses = @courses.map do |course|
      configured_program = @program_by_course.fetch(course.fetch("slug"), { "program" => [] }).fetch("program", [])
      activities = decorate_program_steps(configured_program)
      course.merge(
        "program" => activities,
        "chapter_count" => course.fetch("chapters", []).size,
        "next_activity" => activities.find { |activity| activity.fetch("progress_state") == "available" }
      )
    end
    @lesson_count = @dashboard_courses.sum { |course| course.fetch("program").size }
    @chapter_count = @dashboard_courses.sum { |course| course.fetch("chapter_count") }
    @starting_course = @dashboard_courses.find { |course| course.fetch("slug") == "inizia-con-posturacorretta" } || @dashboard_courses.first
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
    load_student_lessons_program
    calendar = YAML.safe_load_file(GROUP_LESSON_CALENDAR_PATH, permitted_classes: [], aliases: false).fetch("calendar")
    @active_lesson_programs = calendar.fetch("active_programs", [])
    load_dashboard_agenda
    @selected_participation = params[:participation].presence_in(%w[group individual])
  end

  def load_student_lessons_program
    program = YAML.safe_load_file(LESSON_PROGRAM_PATH, permitted_classes: [], aliases: false).fetch("program")
    @student_lessons_program_title = program.fetch("title")
    stages = program.fetch("stages", [])
    @student_internship_stages = stages.select { |stage| stage.dig("internship", "visibility") == "trainee" } if posturacorretta_trainee?
    sheet_type = program.fetch("sheet_type", "practical")
    # L'unità del programma è la lezione: dopo le prime due introduzioni,
    # ciascuna riga corrisponde a un singolo capitolo/scheda, non al corso
    # intero. Il corso resta come contesto editoriale della scheda.
    @student_lessons_program = program.fetch("lessons").map do |lesson|
      chapter_links = [lesson["theory_chapter"], *lesson.fetch("additional_chapters", [])].compact.map do |chapter|
        chapter.merge(
          "chapter_type" => sheet_type,
          "path" => posturacorretta_course_chapter_path(
            corso: chapter.fetch("course_key"),
            capitolo: chapter.fetch("chapter_key")
          )
        )
      end
      release_at = @course_release_schedule[lesson.dig("course", "key")]
      lesson.merge(
        "stage" => stages.find { |stage| stage.fetch("lesson_numbers", []).include?(lesson.fetch("number")) },
        "chapter_links" => chapter_links,
        "release_at" => release_at&.iso8601,
        "release_locked" => release_at.present? && release_at > Time.current
      )
    end
  end

  def posturacorretta_trainee?
    return true if Current.user&.superadmin_user?
    return false unless Current.user&.profile

    brand_node = Domain.find_by(hostname: "posturacorretta.org")&.node
    return false unless brand_node

    Current.user.role_assignments.where(role: :operator, role_operator: "tirocinante", context: brand_node).exists?
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


    profile = Current.user&.profile
    commitments = if Current.user&.superadmin_user?
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
    @lesson_content = ""
    @lesson_access_allowed = @lesson.fetch("access", "free") == "free" || Current.user&.superadmin_user?
    return unless @lesson_access_allowed
    return if content_path.blank?

    lesson_path = resolve_content_path(content_path)
    return unless lesson_path

    @lesson_content = lesson_path.read.sub(/\n<!--\s*advanced\s*-->\s*\n/i, "\n")
  end

  def resolve_content_path(content_path)
    relative = content_path.to_s
    candidates = [CONTENT_ROOT.join(relative).cleanpath, DATA_ROOT.join(relative).cleanpath]
    candidates.find do |candidate|
      candidate.to_s.start_with?("#{DATA_ROOT}/") && candidate.extname == ".md" && candidate.file?
    end
  end
  end
end
