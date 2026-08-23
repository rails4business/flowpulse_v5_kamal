require "test_helper"

class PosturacorrettaSemeControllerTest < ActionDispatch::IntegrationTest
  test "shows the curriculum home without replacing the current home" do
    get posturacorretta_seme_path

    assert_response :success
    assert_select "h1", text: "PosturaCorretta in un mese"
    assert_select "nav[aria-label='Navigazione PosturaCorretta Seme']"
    assert_select "a", text: "Blog"
    assert_select "a", text: "Centri"
    assert_select "h1", text: "PosturaCorretta in un mese"
    assert_select "h2", text: "L'incontro con la salute e con le metodiche posturali"
    assert_select "a[href='#{posturacorretta_seme_percorso_path}']", text: /Percorso|Vedi tutto il percorso/
  end

  test "shows the first month course index separately from its visual home" do
    get posturacorretta_seme_path(stage: "primo-mese")

    assert_response :success
    assert_select "p", text: "Indice del corso"
    assert_select "h2", text: "L'incontro con la salute e con le metodiche posturali"
    assert_select "h2", count: 10
  end

  test "shows courses grouped into the educational path" do
    get posturacorretta_seme_percorso_path

    assert_response :success
    assert_select "h1", text: "Parti dalle basi e approfondisci un corso alla volta"
    assert_select "h3", text: "PosturaCorretta in un mese"
    assert_select "h3", text: "Postura e Fisiologia"
    assert_select "h2", text: "Postura e Recupero"
    assert_select "h3", text: "Igiene Posturale"
    assert_select "[role='progressbar']"
    assert_select "a[aria-label='Apri il corso PosturaCorretta in un mese'][href='#{posturacorretta_seme_path(stage: "primo-mese")}']"
    assert_select "a[aria-label='Apri il corso Igiene Posturale'][href='#{posturacorretta_seme_path(stage: "accademia", module: "igiene-posturale")}']"
  end

  test "shows a base lesson and keeps its advanced content out of the public response" do
    get posturacorretta_seme_path(stage: "primo-mese", lesson: "00-incontro-salute-metodiche")

    assert_response :success
    assert_select "h1", text: "PosturaCorretta in un mese"
    assert_select "#advanced-title", text: "Approfondimento avanzato"
    assert_includes response.body, "Il mio incontro con la salute"
    assert_select "#participation-title", text: "Scegli come seguire questa lezione"
    assert_select "h3", text: "Autonomia"
    assert_select "h3", text: "Gruppo"
    assert_select "h3", text: "Individuale"
    assert_not_includes response.body, "Preparare e condurre la lezione"
    assert_not_includes response.body, "Obiettivi per chi si prepara a insegnare"
  end

  test "shows the student dashboard frontend" do
    get posturacorretta_seme_student_dashboard_path(participation: "group")

    assert_response :success
    assert_select "h1", text: "Dashboard studente"
    assert_select "p", text: "Gruppo"
    assert_select "[role='progressbar']"
  end

  test "shows the teacher dashboard frontend preview" do
    get posturacorretta_seme_teacher_dashboard_path

    assert_response :success
    assert_select "h1", text: "Dashboard insegnante"
    assert_select "span", text: "ANTEPRIMA FRONTEND"
    assert_select "h2", text: "Lezioni da preparare"
  end

  test "loads academy modules and markdown from the existing academy source" do
    get posturacorretta_seme_path(stage: "accademia", module: "igiene-posturale", lesson: "mobilita-articolare")

    assert_response :success
    assert_select "h1", text: "Igiene Posturale"
    assert_includes response.body, "Mobilità articolare"
    assert_select "#advanced-title", text: "Approfondimento avanzato"
  end
end
