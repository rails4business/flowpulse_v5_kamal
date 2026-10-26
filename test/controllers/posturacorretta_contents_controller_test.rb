require "test_helper"

class PosturacorrettaContentsControllerTest < ActionDispatch::IntegrationTest
  test "renders the YAML Content course and its chapters without a separate sheets tab" do
    get posturacorretta_course_path(corso: "inizia-con-posturacorretta")

    assert_response :success
    assert_select "h1", text: "La prima settimana con PosturaCorretta"
    assert_select "#capitoli a", count: 0
    assert_select "#capitoli", text: /In arrivo/
    assert_select "#capitoli", text: /Errori frequenti quando si inizia/
    assert_select "nav[aria-label='Contenuti del corso']", count: 0
    assert_select "#schede-pratiche", count: 0

    get posturacorretta_course_chapter_path(
      corso: "inizia-con-posturacorretta",
      capitolo: "benefici-postura-problemi-posturali"
    )

    assert_redirected_to posturacorretta_course_url(corso: "inizia-con-posturacorretta")
    assert_equal "Il capitolo è pubblicato nell’indice, ma il contenuto è ancora in preparazione.", flash[:alert]
  end

  test "redirects the removed sheets view to the canonical course" do
    get posturacorretta_course_path(corso: "inizia-con-posturacorretta", vista: "schede")

    assert_redirected_to posturacorretta_course_url(corso: "inizia-con-posturacorretta")
    assert_response :moved_permanently
  end
end
