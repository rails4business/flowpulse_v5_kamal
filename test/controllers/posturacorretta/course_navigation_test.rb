require "test_helper"

class Posturacorretta::CourseNavigationTest < ActionDispatch::IntegrationTest
  setup do
    owner = User.create!(email_address: "course-navigation@example.com", password: "password123")
    assignment = RoleAssignment.create!(profile: owner.create_profile!(display_name: "Course owner"), role: :ideatore)
    @brand = Node.create!(slug: "posturacorretta", title: "PosturaCorretta", role_assignment: assignment,
      status: "published", visibility: "public")
    Domain.create!(hostname: "posturacorretta-navigation.test", path_slug: "posturacorretta",
      node: @brand, role_assignment: assignment, home_mode: "node")
    host! "posturacorretta-navigation.test"
    @line = create_node("inizia-con-posturacorretta", "Inizia con PosturaCorretta", "course_line", @brand)
    @course = create_node("corso-introduzione-al-percorso-integrato", "Inizia il percorso", "course", @line)
    @lesson = create_node("introduzione-al-percorso-integrato", "Lezione · Inizia il percorso", "course_lesson", @course)
    @content = Content.create!(node: @course, key: "introduzione-percorso-integrato-posturacorretta",
      slug: "introduzione-percorso-integrato-posturacorretta", title: @course.title, format: "course",
      publication_status: "published", publication_visibility: "public", body_md: "Presentazione del corso.")
    @course.update!(show_content: @content)
    Content.create!(node: @lesson, parent: @content, key: "navigation-first-chapter", slug: "primo-capitolo",
      title: "Primo capitolo", format: "chapter", publication_status: "published", publication_visibility: "public")
  end

  test "Home opens the course and the aside selects only the course" do
    get posturacorretta_path

    assert_response :success
    course_path = posturacorretta_course_path(corso: @content.slug)
    assert_select ".pc-intro-program-list__row.is-course a[href=?]", course_path, text: @course.title
    assert_select ".pc-intro-program-list__row.is-lesson a[href=?]", lesson_path(@lesson)

    get course_path

    assert_response :success
    assert_select "[data-course-video-placeholder]"
    assert_select "#line-learning-aside nav[aria-label='Programma della linea']" do
      assert_select "a[aria-current='page']", count: 1
      assert_select "a[aria-current='page'][href=?]", course_path
      assert_select "a[data-scroll-selected-target='item'][href=?]", course_path
      assert_select "a[href=?]:not([aria-current])", lesson_path(@lesson)
    end
  end

  test "lesson show selects only the lesson and keeps the course link available" do
    get lesson_path(@lesson)

    assert_response :success
    assert_select "#journey-lesson-title", text: "Inizia il percorso"
    assert_select "#line-learning-aside nav[aria-label='Programma della linea']" do
      assert_select "a[aria-current='page']", count: 1
      assert_select "a[aria-current='page'][href=?]", lesson_path(@lesson)
      assert_select "a[data-scroll-selected-target='item'][href=?]", lesson_path(@lesson)
      assert_select "a[href=?]:not([aria-current])", posturacorretta_course_path(corso: @content.slug)
    end
  end

  test "recovery sheet keeps course and individual lesson destinations distinct" do
    line = create_node("area-massaggio-terapie-manuali-tecniche-corporee", "Recupero e terapie manuali", "course_line", @brand)
    course = create_node("corso-recupero-navigazione", "Corso recupero", "course", line)
    first = create_node("recupero-prima-lezione", "Prima lezione", "course_lesson", course)
    second = create_node("recupero-seconda-lezione", "Seconda lezione", "course_lesson", course)
    course_path = posturacorretta_course_path(corso: course.slug)

    get posturacorretta_path(area: "espressione")

    assert_response :success
    assert_select ".pc-intro-program-list__row.is-course a[href=?]", course_path, text: course.title
    [first, second].each do |lesson|
      assert_select ".pc-intro-program-list__row.is-lesson a[href=?]", lesson_path(lesson)
    end

    get course_path
    assert_response :success
    assert_select "h1", text: course.title

    get lesson_path(second)
    assert_response :success
    assert_select "nav[aria-label='Programma della linea'] a[aria-current='page']", count: 1
    assert_select "nav[aria-label='Programma della linea'] a[aria-current='page'][href=?]", lesson_path(second)
  end

  private

    def create_node(slug, title, view_type, parent)
      Node.create!(slug: slug, title: title, view_type: view_type, parent: parent,
        role_assignment: @brand.role_assignment, status: "published", visibility: "public")
    end

    def lesson_path(lesson)
      posturacorretta_postura_recupero_path(tappa: lesson.slug, tab: "online")
    end
end
