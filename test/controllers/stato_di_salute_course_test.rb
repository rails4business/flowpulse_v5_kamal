require "test_helper"

class StatoDiSaluteCourseTest < ActionDispatch::IntegrationTest
  test "shows four introductory chapters and seven distinct health areas" do
    get stato_di_salute_course_path

    assert_response :success
    assert_select "aside ol li", count: 11
    assert_select "aside", text: /Qual è il tuo punto di partenza?/
    assert_select "aside", text: /Evoluzione e connessione/
    assert_select "aside", text: /Matrice per orientarsi/, count: 0

    get stato_di_salute_course_chapter_path("consapevolezza")
    assert_response :success
    assert_select "h2", text: "Consapevolezza"
  end

  test "redirects old health chapters to their new owners" do
    get posturacorretta_course_path(corso: "il-tuo-stato-di-salute")
    assert_redirected_to stato_di_salute_course_url

    get posturacorretta_course_chapter_path(corso: "il-tuo-stato-di-salute", capitolo: "qual-e-il-tuo-punto-di-partenza")
    assert_redirected_to stato_di_salute_course_chapter_url("qual-e-il-tuo-punto-di-partenza")

    get posturacorretta_course_chapter_path(corso: "il-tuo-stato-di-salute", capitolo: "matrice-per-orientarsi-salute-benessere")
    assert_redirected_to percorso_integrato_course_chapter_url("matrice-per-orientarsi-salute-benessere")
  end
end
