require "test_helper"

class PosturacorrettaSemeControllerTest < ActionDispatch::IntegrationTest
  test "keeps course titles program activities and learning chapters in separate yaml files" do
    titles = YAML.safe_load_file(PosturacorrettaSemeController::DIDACTIC_PATH, permitted_classes: [], aliases: false)
    program = YAML.safe_load_file(PosturacorrettaSemeController::GUIDED_PATH, permitted_classes: [], aliases: false)
    learning = YAML.safe_load_file(PosturacorrettaSemeController::LEARNING_PATH, permitted_classes: [], aliases: false)

    assert titles.dig("path", "courses", 0, "title").present?
    assert_nil titles.dig("path", "courses", 0, "chapters")
    assert_equal ["course_slug", "activities"], program.fetch("courses").first.keys
    assert_equal ["source"], program.dig("courses", 0, "activities", 0).keys
    assert_equal ["course_slug", "modules"], learning.fetch("courses").first.keys
    assert_equal ["slug", "title", "chapters"], learning.dig("courses", 0, "modules", 0).keys
    base_lesson = YAML.safe_load_file(PosturacorrettaSemeController::GUIDED_ACTIVITIES_ROOT.join("lezione_pratica_primo_mese.yml"), permitted_classes: [], aliases: false)
    assert_equal "lesson", base_lesson.fetch("type")
    assert_equal %w[base advanced], base_lesson.fetch("levels").keys
    assert_equal %w[student teacher_trainee], base_lesson.dig("participation", "roles").keys
    assert_equal "teacher_master", base_lesson.dig("delivery", "role")
    assert_equal "teacher", base_lesson.dig("levels", "base", "teaching", "minimum_qualification")
    assert_equal "teacher_master", base_lesson.dig("levels", "advanced", "teaching", "minimum_qualification")
    internship = base_lesson.dig("participation", "roles", "teacher_trainee", "internship")
    assert internship.fetch("supervisor_required")
    assert_equal "teacher_master", internship.fetch("supervisor_qualification")
    assert_equal %w[shadowing supervised_teaching], internship.fetch("modes").keys
    assert_equal "insegnamenti-metodiche-posturali", base_lesson.dig("modules", 0, "module_slug")
  end

  test "shows appointments and chapters as tabs in the course overview main" do
    get posturacorretta_course_path(corso: "postura-corretta-in-un-mese")

    assert_response :success
    assert_select "header"
    assert_select "header img[src*='posturacorretta_home.png']", count: 1
    assert_select "header h1", text: "PosturaCorretta in un mese"
    assert_select "header", text: /2 attività guidate · 11 capitoli/
    assert_select "header a[href='#{posturacorretta_course_chapter_path(corso: "postura-corretta-in-un-mese", capitolo: "incontro-salute-metodiche")}']", text: "Inizia"
    assert_not_includes response.body, 'header class="border-b border-slate-200 bg-[#F6F7F4] p-4 sm:p-6 lg:p-8"'
    assert_select "nav[aria-label='Navigazione del corso']", count: 0
    assert_select "h2", text: "Incontri e lezioni"
    assert_select "p", text: "Appuntamenti"
    assert_select "nav[aria-label='Contenuti del corso'] a[aria-current='page']", text: /Percorso guidato/
    assert_select "nav[aria-label='Contenuti del corso'][role='tablist'] a[role='tab'][aria-selected='true']", count: 1
    assert_select "nav[aria-label='Contenuti del corso'] a", text: /Corso online/
    assert_select "nav[aria-label='Contenuti del corso'] a:first-child", text: /Corso online/
    assert_select "#incontri-lezioni h3", text: /Presentazione del metodo/
    assert_select "#incontri-lezioni ol[aria-label='Attività del percorso guidato'] li", count: 2
    activity_path = posturacorretta_course_lesson_path(corso: "postura-corretta-in-un-mese", attivita: "presentazione-del-metodo")
    assert_select "#incontri-lezioni a[href='#{new_session_path(return_to: activity_path)}']", text: /Accedi per prenotare/
    assert_select "#incontri-lezioni span[aria-disabled='true']", text: /Da sbloccare/
    assert_select "#incontri-lezioni a[href='#{new_session_path(return_to: posturacorretta_seme_student_dashboard_path)}']", text: /Vedi tutti i corsi nella dashboard/
    assert_select "#capitoli", count: 0
    assert_select "nav[aria-label='Indice generale dei corsi'] a[aria-current='page']", text: /PosturaCorretta in un mese/
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a[href='#{posturacorretta_path}']", text: "Home"
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] summary", text: /Esplora/
    assert_select "[aria-label='Esplora PosturaCorretta'] a", text: "Lezioni", count: 0
    assert_select "[aria-label='Esplora PosturaCorretta'] a", text: "Corso online", count: 0
    assert_select "a", text: "Contenuti"
    assert_select "[aria-label='Esplora PosturaCorretta'] a[href='#{posturacorretta_contenuti_path}']", text: "Contenuti"
    assert_select "[aria-label='Esplora PosturaCorretta'] a[href='#{posturacorretta_corsi_path}']", text: "Corsi"

    get posturacorretta_course_path(corso: "postura-corretta-in-un-mese", vista: "capitoli")
    assert_response :success
    assert_select "nav[aria-label='Contenuti del corso'] a[aria-current='page']", text: /Corso online/
    assert_select "#capitoli.rounded-b-2xl", count: 1
    assert_select "h2", text: "Corso online"
    assert_select "p", text: "Studio in autonomia"
    assert_select "#capitoli a", text: /L'incontro con la salute e con le metodiche posturali/
    assert_select "#capitoli span", text: "Capitolo 01"
    assert_select "#capitoli ol.divide-y", count: 1
    assert_select "#incontri-lezioni", count: 0
  end

  test "keeps program activities sequential and redirects a locked activity" do
    get posturacorretta_course_lesson_path(corso: "postura-corretta-in-un-mese", attivita: "pratica-guidata-primo-mese")

    assert_redirected_to posturacorretta_course_lesson_url(corso: "postura-corretta-in-un-mese", attivita: "presentazione-del-metodo")
    assert_equal "Completa prima l’attività precedente.", flash[:alert]

    get posturacorretta_course_lesson_path(corso: "postura-corretta-in-un-mese", attivita: "presentazione-del-metodo")

    assert_response :success
    assert_select "header a[aria-label^='Torna all']", text: /PosturaCorretta in un mese/
    assert_select "nav[aria-label='Navigazione del corso'] [role='tab'][aria-current='page']", text: /Percorso guidato/
    assert_select "nav[aria-label='Navigazione del corso'] a[href='#{posturacorretta_course_chapter_path(corso: "postura-corretta-in-un-mese", capitolo: "incontro-salute-metodiche")}']", text: /Corso online/
    assert_select "#programma-aside #course-aside-title", count: 0
    assert_select "nav[aria-label='Esplora PosturaCorretta']", count: 0
    assert_select "nav[aria-label='Indice del corso'] a[aria-current='page']", text: /Presentazione del metodo/
    assert_select "nav[aria-label='Indice del corso'] h2", text: "Incontri e lezioni"
    assert_select "nav[aria-label='Indice del corso'] span.bg-amber-200", count: 2
    assert_select "nav[aria-label='Indice del corso'] span[aria-disabled='true']", text: /Lezione pratica PosturaCorretta in un mese/
    assert_select "#scheda-attivita h2", text: "Presentazione del metodo"
    assert_select "#scheda-attivita", text: /Programma dell'incontro iniziale/
    assert_select "#scheda-attivita #participation-role-title", text: "Partecipi come"
    assert_select "#scheda-attivita", text: /Studente/
    assert_select "#scheda-attivita a[href='#{new_session_path(return_to: posturacorretta_course_lesson_path(corso: "postura-corretta-in-un-mese", attivita: "presentazione-del-metodo"))}']", text: "Accedi per prenotare"
  end

  test "keeps the former home at the three projects page" do
    get posturacorretta_three_projects_path

    assert_response :success
    assert_select "#ecosystem-map-title", text: "I tre progetti intorno alla persona"
  end

  test "keeps the previous visual home as integrated paths" do
    get posturacorretta_seme_integrated_paths_path

    assert_response :success
    assert_select "h1", text: "Costruisci il percorso partendo dalla postura"
    assert_select "h2", text: "L'incontro con la salute e con le metodiche posturali"
  end

  test "redirects the former chapters index to the course chapters section" do
    get posturacorretta_course_chapters_path(corso: "postura-corretta-in-un-mese")

    assert_redirected_to posturacorretta_course_url(corso: "postura-corretta-in-un-mese", vista: "capitoli")
  end

  test "shows courses grouped into the educational path" do
    get posturacorretta_path

    assert_response :success
    assert_select "nav[aria-label='Indice generale']", count: 0
    assert_select "h1", text: "Percorso educativo PosturaCorretta"
    assert_select "h3", text: "PosturaCorretta in un mese"
    assert_select "h3", text: "Postura e Fisiologia"
    assert_select "h2", text: "Postura e Recupero"
    assert_select "h3", text: "Igiene Posturale"
    assert_select "p", text: "Sezione del percorso"
    assert_select "span", text: "Corso 01", minimum: 1
    assert_select "a[href='#{posturacorretta_course_path(corso: "postura-corretta-in-un-mese", vista: "capitoli")}'][aria-label='Apri il corso PosturaCorretta in un mese']"
    assert_select "a[href='#{posturacorretta_course_path(corso: "igiene-posturale", vista: "capitoli")}'][aria-label='Apri il corso Igiene Posturale']"
  end

  test "shows a base lesson and keeps its advanced content out of the public response" do
    get posturacorretta_course_chapter_path(corso: "postura-corretta-in-un-mese", capitolo: "incontro-salute-metodiche")

    assert_response :success
    assert_select "h1", text: "PosturaCorretta in un mese"
    assert_select "#advanced-title", text: "Approfondimento avanzato"
    assert_includes response.body, "Il mio incontro con la salute"
    assert_select "p", text: "Capitolo del corso"
    assert_select "header a[aria-label^='Torna all']", text: /PosturaCorretta in un mese/
    assert_select "nav[aria-label='Navigazione del corso'] [role='tab'][aria-current='page']", text: /Corso online/
    assert_select "nav[aria-label='Navigazione del corso'] a[href='#{posturacorretta_course_lesson_path(corso: "postura-corretta-in-un-mese", attivita: "presentazione-del-metodo")}']", text: /Percorso guidato/
    assert_select "#seme-aside #course-aside-title", count: 0
    assert_select "nav[aria-label='Esplora PosturaCorretta']", count: 0
    assert_select "nav[aria-label='Indice del corso'] h2", text: "Indice dei capitoli"
    assert_select "nav[aria-label='Indice del corso'] a[aria-current='page'] span", text: "Capitolo 01"
    assert_select "#participation-title", count: 0
    assert_select "nav[aria-label='Incontri, lezioni e capitoli']", count: 0
    assert_not_includes response.body, "Preparare e condurre la lezione"
    assert_not_includes response.body, "Obiettivi per chi si prepara a insegnare"
  end

  test "shows the student dashboard frontend" do
    get posturacorretta_seme_student_dashboard_path
    assert_redirected_to new_session_url

    sign_in(create_test_user("seme-student@example.com"))
    get posturacorretta_seme_student_dashboard_path(participation: "group")

    assert_response :success
    assert_select "h1", text: "Dashboard studente"
    assert_select "p", text: "Gruppo"
    assert_select "[role='progressbar']"
  end

  test "shows the teacher dashboard frontend preview" do
    get posturacorretta_seme_teacher_dashboard_path
    assert_redirected_to new_session_url

    sign_in(create_test_user("seme-teacher-preview@example.com"))
    get posturacorretta_seme_teacher_dashboard_path

    assert_response :success
    assert_select "h1", text: "Dashboard insegnante"
    assert_select "span", text: "ANTEPRIMA FRONTEND"
    assert_select "h2", text: "Lezioni da preparare"
  end

  test "loads academy modules and markdown from the existing academy source" do
    get posturacorretta_course_chapter_path(corso: "igiene-posturale", capitolo: "mobilita-articolare")

    assert_response :success
    assert_select "h1", text: "Igiene Posturale"
    assert_includes response.body, "Mobilità articolare"
    assert_select "#advanced-title", text: "Approfondimento avanzato"
  end

  test "redirects the former seme lesson url to the new educational path" do
    get posturacorretta_seme_path(stage: "primo-mese", lesson: "02-benefici")

    assert_redirected_to posturacorretta_course_chapter_url(corso: "postura-corretta-in-un-mese", capitolo: "benefici-postura-corretta")
    assert_response :moved_permanently
  end

  test "redirects the former course catalog to the new home" do
    get posturacorretta_seme_percorso_path

    assert_redirected_to posturacorretta_url
    assert_response :moved_permanently
  end

  test "opens every course through its course overview" do
    get posturacorretta_course_path(corso: "postura-e-fisiologia")

    assert_response :success
    assert_select "h1", text: "Postura e Fisiologia"
    assert_select "h2", text: "Incontri e lezioni"
    assert_select "p", text: "Gli incontri e le lezioni di questo corso sono in preparazione."
    assert_select "nav[aria-label='Contenuti del corso'] a", text: /Corso online/

    get posturacorretta_course_path(corso: "postura-e-fisiologia", vista: "capitoli")
    assert_response :success
    assert_select "#capitoli a", text: /Matrice, ambiti, aree e paradigmi/
    assert_select "#capitoli a", text: /Tre possibilità per continuare/

    get posturacorretta_course_chapter_path(corso: "postura-e-fisiologia", capitolo: "tre-possibilita-per-continuare")
    assert_response :success
    assert_select "article", text: /Continuare nel percorso educativo/
    assert_select "article", text: /Costruire un percorso integrato/
    assert_select "article", text: /Giardino del Corpo/
  end

  test "redirects legacy program and chapter urls to canonical course routes" do
    get posturacorretta_programma_path(corso: "postura-corretta-in-un-mese", attivita: "pratica-guidata-primo-mese")
    assert_redirected_to posturacorretta_course_lesson_url(corso: "postura-corretta-in-un-mese", attivita: "pratica-guidata-primo-mese")
    assert_response :moved_permanently

    get posturacorretta_percorso_educativo_path(corso: "postura-corretta-in-un-mese", capitolo: "incontro-salute-metodiche")
    assert_redirected_to posturacorretta_course_chapter_url(corso: "postura-corretta-in-un-mese", capitolo: "incontro-salute-metodiche")
    assert_response :moved_permanently
  end

  private

  def create_test_user(email)
    User.create!(email_address: email, password: "password123", password_confirmation: "password123")
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
    assert_response :redirect
  end
end
