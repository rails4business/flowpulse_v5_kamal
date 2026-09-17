require "test_helper"

class PosturacorrettaSemeControllerTest < ActionDispatch::IntegrationTest
  test "keeps path references content tree program activities and legacy learning sources separate" do
    titles = YAML.safe_load_file(PosturacorrettaSemeController::DIDACTIC_PATH, permitted_classes: [], aliases: false)
    contents = YAML.safe_load_file(PosturacorrettaSemeController::CONTENT_CATALOG_PATH, permitted_classes: [], aliases: false)
    program = YAML.safe_load_file(PosturacorrettaSemeController::GUIDED_PATH, permitted_classes: [], aliases: false)
    learning = YAML.safe_load_file(PosturacorrettaSemeController::LEARNING_PATH, permitted_classes: [], aliases: false)

    assert_equal({ "content_id" => "inizia-con-posturacorretta" }, titles.dig("path", "courses", 0))
    assert_equal "course", contents.dig("contents", 0, "format")
    assert_equal "inizia-con-posturacorretta", contents.dig("contents", 1, "parent_id")
    assert_equal "chapter", contents.dig("contents", 1, "format")
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

  test "shows chapters as the single course content structure" do
    travel_to Time.zone.parse("2026-09-21 09:01") do
      get posturacorretta_course_path(corso: "inizia-con-posturacorretta")

    assert_response :success
    assert_select "header"
    assert_select "header img[src*='posturacorretta_home.png']", count: 1
    assert_select "header h1", text: "Inizia con PosturaCorretta"
    assert_select "header", text: /7 capitoli/
    assert_select "header a[href='#{posturacorretta_course_chapter_path(corso: "inizia-con-posturacorretta", capitolo: "incontro-salute-metodiche")}']", text: "Inizia"
    assert_not_includes response.body, 'header class="border-b border-slate-200 bg-[#F6F7F4] p-4 sm:p-6 lg:p-8"'
    assert_select "nav[aria-label='Navigazione del corso']", count: 0
    assert_select "nav[aria-label='Contenuti del corso']", count: 0
    assert_select "#schede-pratiche", count: 0
    assert_select "#capitoli.rounded-2xl", count: 1
    assert_select "h2", text: "Corso online"
    assert_select "p", text: "Studio in autonomia"
    assert_select "#capitoli a", text: /L'incontro con la salute e con le metodiche posturali/
    assert_select "#capitoli a", text: /Prima scheda esercizi e video/
    assert_select "#capitoli span", text: "Capitolo 01"
    assert_select "#capitoli ol.divide-y", count: 1
    assert_select "nav[aria-label='Indice percorso'] a[aria-current='page']", text: /Inizia con PosturaCorretta/
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a[aria-current='page']", text: "Home"
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a", text: "Lezioni"
      assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a", text: "Appuntamenti", count: 0
    end
  end

  test "keeps program activities sequential and redirects a locked activity" do
    get posturacorretta_course_lesson_path(corso: "postura-corretta-in-un-mese", attivita: "pratica-guidata-primo-mese")

    assert_redirected_to posturacorretta_course_lesson_url(corso: "postura-corretta-in-un-mese", attivita: "presentazione-del-metodo")
    assert_equal "Completa prima l’attività precedente.", flash[:alert]

    get posturacorretta_course_lesson_path(corso: "postura-corretta-in-un-mese", attivita: "presentazione-del-metodo")

    assert_response :success
    assert_select "header a[aria-label^='Torna all']", text: /PosturaCorretta in un mese/
    assert_select "nav[aria-label='Navigazione del corso']", count: 0
    assert_select "#programma-aside #course-aside-title", count: 0
    assert_select "nav[aria-label='Esplora PosturaCorretta']", count: 0
    assert_select "nav[aria-label='Indice del corso'] a[aria-current='page']", text: /Presentazione del metodo/
    assert_select "nav[aria-label='Indice del corso'] h2", text: "Schede del corso"
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

  test "redirects the former course chapters index to the book" do
    get posturacorretta_course_chapters_path(corso: "postura-corretta-in-un-mese")

    assert_redirected_to book_chapter_url(book_slug: "postura-corretta-in-un-mese", id: "copertina")
  end

  test "shows courses grouped into the educational path" do
    get posturacorretta_path

    assert_response :success
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a", text: "Lezioni"
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a", text: "Appuntamenti", count: 0
    assert_select "nav[aria-label='Indice generale']", count: 0
    assert_select "h1", text: "Percorso educativo PosturaCorretta"
    assert_select "nav[aria-label='Navigazione app PosturaCorretta'] > a", count: 3
    assert_select "nav[aria-label='Navigazione app PosturaCorretta'] details summary", text: /Esplora/
    assert_select "nav[aria-label='Navigazione app PosturaCorretta'] a[href='#{posturacorretta_profile_path}']", text: /Profilo/
    assert_select "nav[aria-label='Navigazione app PosturaCorretta'] a.pc-app-logo img", count: 1
    assert_select "#pc-week-focus-title", text: "Inizia con PosturaCorretta"
    assert_select "link[rel='manifest'][href='#{posturacorretta_pwa_manifest_path}']"
    assert_select "h3", text: "Inizia con PosturaCorretta"
    assert_select "h3", text: "Postura e Fisiologia"
    assert_select "h2", text: "Recupera con la terapia manuale"
    assert_select "h2", text: "Muoviti ed esplora"
    assert_select "h2", text: "Ascolta gli aspetti vitali"
    assert_select "h2", text: "Nutri il corpo"
    assert_select "h2", text: "Regola con le piante officinali"
    assert_select "h3", text: "Igiene Posturale"
    assert_includes response.body, "Scopri come funziona il tuo corpo, e riattiva i tuoi sistemi!"
    assert_select "span", text: "Corso 01", minimum: 1
    assert_select "a[href='#{posturacorretta_course_path(corso: "inizia-con-posturacorretta")}'][aria-label='Apri il corso Inizia con PosturaCorretta']", count: 0
    assert_select "a[href='#{posturacorretta_course_path(corso: "igiene-posturale")}'][aria-label='Apri il corso Igiene Posturale']", count: 0
    assert_select "details > summary", text: /Inizia con PosturaCorretta/, minimum: 1
    assert_select "h3", text: "Intro: basi e fondamenti", count: 0
    assert_select "a[href='#{posturacorretta_course_chapter_path(corso: "inizia-con-posturacorretta", capitolo: "incontro-salute-metodiche")}']", text: /L'incontro con la salute/
    assert_select "div", text: /I benefici di una postura corretta.*Uscita/m
    assert_includes response.body, "Demo disponibile"
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] summary", text: /Esplora/
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] > a", text: "Come funziona", count: 0
    assert_select "[aria-label='Esplora PosturaCorretta'] a[href='#{posturacorretta_guida_path(sezione: "accademia", capitolo: "educazione")}']", text: "Come funziona"
  end

  test "serves the installable PosturaCorretta PWA files" do
    get posturacorretta_pwa_manifest_path

    assert_response :success
    assert_equal "application/manifest+json", response.media_type
    manifest = JSON.parse(response.body)
    assert_equal "PosturaCorretta", manifest.fetch("name")
    assert_equal "/posturacorretta", manifest.fetch("start_url")
    assert_equal "/posturacorretta", manifest.fetch("scope")

    get posturacorretta_pwa_service_worker_path

    assert_response :success
    assert_equal "text/javascript", response.media_type
    assert_includes response.body, "posturacorretta-it-shell-v1"
    assert_includes response.body, "/appuntamenti"
    assert_includes response.body, "OFFLINE_URL"
    assert_not_includes response.body, "cache.put(request, copy)"

    get posturacorretta_pwa_offline_path

    assert_response :success
    assert_select "h1", text: "Connessione non disponibile"
  end

  test "serves the PWA from the root of the dedicated domain" do
    host! "posturacorretta.org"

    get pwa_manifest_path

    assert_response :success
    manifest = JSON.parse(response.body)
    assert_equal "/", manifest.fetch("start_url")
    assert_equal "/", manifest.fetch("scope")

    get pwa_service_worker_path

    assert_response :success
    assert_equal "/", response.headers.fetch("Service-Worker-Allowed")
    assert_includes response.body, 'const APP_SCOPE = "/"'
  end

  test "keeps academy as a backup without duplicating the how it works tabs" do
    get posturacorretta_accademia_path

    assert_response :success
    assert_select "#btn-tab-curriculum", count: 0
    assert_select "#btn-tab-guide", count: 0
    assert_not_includes response.body, "🎓 Il Programma dell'Accademia"
    assert_not_includes response.body, "📖 Come funziona?"
  end

  test "opens how it works for a signed in user without a tutor role" do
    sign_in(create_test_user("posturacorretta-guide-reader@example.com"))

    get posturacorretta_guida_path(sezione: "accademia", capitolo: "educazione")

    assert_response :success
    assert_select "h1", text: /Educazione al corpo e alla salute/
  end

  test "serves the triathlon handout as a PDF" do
    get posturacorretta_presentation_path

    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "shows a free chapter as one content without an isolated advanced block" do
    travel_to Time.zone.parse("2026-09-21 09:01") do
      get posturacorretta_course_chapter_path(corso: "inizia-con-posturacorretta", capitolo: "prima-scheda-esercizi-video")

      assert_response :success
      assert_select "h1", text: "Inizia con PosturaCorretta"
      assert_select "span", text: "Libero"
      assert_includes response.body, "Prima scheda esercizi e video"
      assert_select "p", text: "Capitolo del corso"
      assert_select "header a[aria-label^='Torna all']", text: /Inizia con PosturaCorretta/
      assert_select "nav[aria-label='Navigazione del corso']", count: 0
      assert_select "#seme-aside #course-aside-title", count: 0
      assert_select "nav[aria-label='Esplora PosturaCorretta']", count: 0
      assert_select "nav[aria-label='Indice del corso'] h2", text: "Indice dei capitoli"
      assert_select "nav[aria-label='Indice del corso'] a[aria-current='page'] span", text: "Capitolo 05"
      assert_select "#participation-title", count: 0
      assert_select "nav[aria-label='Incontri, lezioni e capitoli']", count: 0
      assert_includes response.body, "Ricevere — massaggio e automassaggio"
      assert_includes response.body, "movimento globale — da collegare"
      assert_not_includes response.body, "Approfondimento avanzato"
    end
  end

  test "does not let superadmin bypass a chapter publication date" do
    superadmin = create_test_user("posturacorretta-preview@example.com")
    superadmin.update!(superadmin: true, active_role: :superadmin)
    sign_in(superadmin)

    get posturacorretta_course_chapter_path(corso: "inizia-con-posturacorretta", capitolo: "benefici-postura-corretta")

    assert_redirected_to posturacorretta_url(anchor: "inizia-con-posturacorretta")
  end

  test "shows the student dashboard frontend" do
    get posturacorretta_seme_student_dashboard_path
    assert_response :success
    assert_select "h2", text: "Programmi attivi"

    user = create_test_user("seme-student@example.com")
    sign_in(user)
    get posturacorretta_seme_student_dashboard_path(participation: "group")

    assert_response :success
    assert_select "h1", text: "Il tuo percorso", count: 0
    assert_select "p", text: "Gruppo"
    assert_select "[role='progressbar']", count: 0
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a[aria-current='page']", text: "Lezioni"
    assert_select "nav[aria-label='Navigazione principale PosturaCorretta'] a[href='#{posturacorretta_path}']", text: "Home"
    assert_select "h1", text: "Programma lezioni", count: 1
    assert_select "ol[aria-label='Lezioni del programma studenti'] > li", count: 40
    assert_select "h2", text: "Inizia con PosturaCorretta"
    assert_select "h2", text: "Postura e Fisiologia"
    assert_select "h2", text: "Rinforzo muscolare"
    assert_select "a[href='#{posturacorretta_course_chapter_path(corso: 'igiene-posturale', capitolo: 'punti-di-tensione')}']", count: 0
    assert_select "span", text: /Punti di tensione/
    assert_includes response.body, "Prima scheda esercizi e video"
    assert_includes response.body, "Disponibile dal"
    assert_select "a", text: "Apri il corso online", count: 0
    assert_select "aside[aria-label='Sorgenti YAML del programma']", count: 0

    other_domain = Domain.find_or_create_by!(hostname: "agenda-esterna.test") do |domain|
      domain.target_controller = "brands/impegno/home"
      domain.target_action = "index"
      domain.locale = "it"
      domain.settings = { auth_slug: "impegno", site_title: "Impegno" }
    end
    profile = Profile.find_or_create_by!(user: user)
    DataCommitment.create!(
      profile: profile,
      created_by_profile: profile,
      domain: other_domain,
      title: "Dettaglio che resta privato",
      kind: "personal",
      status: "planned",
      starts_at: 1.day.from_now.change(hour: 10),
      ends_at: 1.day.from_now.change(hour: 11),
      pricing_type: "none",
      contribution_type: "unpaid"
    )

    get posturacorretta_student_appointments_path
    assert_response :success
    assert_select "a[href='#{posturacorretta_student_appointments_path}']", text: "Appuntamenti"
    assert_select "h2", text: "I tuoi appuntamenti"
    assert_select "h3", text: "Prossimi"
    assert_select "h3", text: "Passati"
    assert_select "li.opacity-50 h4", text: "Dettaglio che resta privato"
    assert_select "a", text: "Apri 1Impegno", count: 0

    get posturacorretta_student_dashboard_path(vista: "calendario")
    assert_redirected_to posturacorretta_student_appointments_path

    get posturacorretta_student_dashboard_path
    assert_response :success
    assert_select "h1", text: "Il tuo percorso", count: 0
  end

  test "student dashboard keeps the PosturaCorretta site context when login is required locally" do
    posturacorretta_domain = Domain.find_or_create_by!(hostname: "posturacorretta.org") do |domain|
      domain.target_controller = "brands/posturacorretta"
      domain.target_action = "home"
      domain.locale = "it"
    end
    posturacorretta_domain.update!(auth_slug: "posturacorretta", auth_enabled: true, auth_default_path: "/posturacorretta/dashboard")

    host! "localhost"
    get posturacorretta_student_dashboard_path

    assert_response :success
    assert_select "h2", text: "Programmi attivi"
  end

  test "shows the teacher dashboard frontend preview" do
    get posturacorretta_seme_teacher_dashboard_path
    assert_redirected_to new_session_url(return_to: posturacorretta_seme_teacher_dashboard_path)

    sign_in(create_test_user("seme-teacher-preview@example.com"))
    get posturacorretta_seme_teacher_dashboard_path

    assert_response :success
    assert_select "h1", text: "Dashboard insegnante"
    assert_select "span", text: "ANTEPRIMA FRONTEND"
    assert_select "h2", text: "Lezioni da preparare"
  end

  test "loads academy modules and markdown from the existing academy source" do
    travel_to Time.zone.parse("2026-10-05 09:01") do
      get posturacorretta_course_chapter_path(corso: "igiene-posturale", capitolo: "mobilita-articolare")

      assert_response :success
      assert_select "h1", text: "Igiene Posturale"
      assert_includes response.body, "Mobilità articolare"
      assert_select "span", text: "Libero"
      assert_select "#advanced-title", count: 0
    end
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
    travel_to Time.zone.parse("2026-09-28 09:01") do
      get posturacorretta_course_path(corso: "postura-e-fisiologia")

    assert_response :success
    assert_select "h1", text: "Postura e Fisiologia"
    assert_select "h2", text: "Corso online"
    assert_select "nav[aria-label='Contenuti del corso']", count: 0
    assert_select "#capitoli a", text: /Le basi delle 5 aree e il programma settimanale/
    assert_select "#capitoli a", text: /Professionisti della salute, del benessere e insegnanti blu/

      get posturacorretta_course_chapter_path(corso: "postura-e-fisiologia", capitolo: "professionisti-salute-benessere-insegnanti-blu")
      assert_response :success
      assert_select "article", text: /Professionisti della salute, del benessere e insegnanti blu/
    end
  end

  test "redirects legacy program and chapter urls to canonical course routes" do
    get posturacorretta_programma_path(corso: "postura-corretta-in-un-mese", attivita: "pratica-guidata-primo-mese")
    assert_redirected_to posturacorretta_course_lesson_url(corso: "postura-corretta-in-un-mese", attivita: "pratica-guidata-primo-mese")
    assert_response :moved_permanently

    get posturacorretta_percorso_educativo_path(corso: "postura-corretta-in-un-mese", capitolo: "incontro-salute-metodiche")
    assert_redirected_to posturacorretta_course_chapter_url(corso: "postura-corretta-in-un-mese", capitolo: "incontro-salute-metodiche")
    assert_response :moved_permanently
  end

  test "displays Canva superadmin links in footer only for superadmin users" do
    get posturacorretta_path
    assert_response :success
    assert_not_includes response.body, "benessereintegrato.my.canva.site"

    superadmin = create_test_user("superadmin-canva@example.com")
    superadmin.update!(superadmin: true)
    sign_in(superadmin)

    get posturacorretta_path
    assert_response :success
    assert_includes response.body, "benessereintegrato.my.canva.site/postura-sito-4-ante-presentazione-servizi-centri-sito-web"
    assert_includes response.body, "benessereintegrato.my.canva.site/home"
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
