require "test_helper"

class PosturacorrettaContentsControllerTest < ActionDispatch::IntegrationTest
  test "renders the YAML Content course and its chapters without a separate sheets tab" do
    get posturacorretta_course_path(corso: "inizia-con-posturacorretta")

    assert_response :success
    assert_select "h1", text: "Inizia con PosturaCorretta"
    assert_select "#capitoli a", count: 5
    assert_select "#capitoli", text: /I 3 errori che tutti fanno/
    assert_select "nav[aria-label='Contenuti del corso']", count: 0
    assert_select "#schede-pratiche", count: 0

    get posturacorretta_course_chapter_path(
      corso: "inizia-con-posturacorretta",
      capitolo: "benefici-postura-corretta"
    )

    assert_response :success
    assert_select "h1", text: "Inizia con PosturaCorretta"
    assert_includes response.body, "I benefici di una postura corretta"
  end

  test "redirects the removed sheets view to the canonical course" do
    get posturacorretta_course_path(corso: "inizia-con-posturacorretta", vista: "schede")

    assert_redirected_to posturacorretta_course_url(corso: "inizia-con-posturacorretta")
    assert_response :moved_permanently
  end
end
