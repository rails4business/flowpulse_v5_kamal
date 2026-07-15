require "test_helper"

class LibroControllerTest < ActionDispatch::IntegrationTest
  BOOK_SLUG = "il-corpo-un-mondo-da-scoprire"
  HIDDEN_BOOK_SLUG = "test-hidden-book"

  setup do
    @superadmin = User.create!(
      email_address: "book-superadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      superadmin: true,
      active_role: :superadmin
    )

    @traveler = User.create!(
      email_address: "book-traveler@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "index should redirect to cover page" do
    get book_url(book_slug: BOOK_SLUG)
    assert_response :redirect
    assert_redirected_to book_chapter_path(book_slug: BOOK_SLUG, id: "copertina")
  end

  test "show should render cover page correctly" do
    get book_chapter_url(book_slug: BOOK_SLUG, id: "copertina")
    assert_response :success
    assert_includes response.body, "Il corpo, un mondo da scoprire"
    assert_includes response.body, "Inizia a leggere"
  end

  test "show should render draft chapter placeholder for guests" do
    get book_chapter_url(book_slug: BOOK_SLUG, id: "parte-1-di-cosa-parleremo-in-questo-libro")
    assert_response :success
    assert_includes response.body, "Parte I - Di cosa parleremo in questo libro"
    assert_includes response.body, "Questo capitolo è attualmente in fase di scrittura/bozza"
  end

  test "show should support chapter pages if valid" do
    get book_chapter_url(book_slug: BOOK_SLUG, id: "il-tuo-corpo-ti-accompagna-ogni-giorno")
    assert_response :success
    assert_includes response.body, "Mentre il corpo ti accompagna, tu ti perdi nello scrolling"
  end

  test "toc shows visual outline numbering without changing index data" do
    get book_chapter_url(book_slug: BOOK_SLUG, id: "parte-1-di-cosa-parleremo-in-questo-libro")

    assert_response :success
    assert_includes response.body, "1. Parte I - Di cosa parleremo in questo libro"
    assert_includes response.body, "1.1. Mentre il corpo ti accompagna, tu ti perdi nello scrolling"
  end

  test "hide access removes chapter from public toc and keeps numbering compact" do
    get book_chapter_url(book_slug: HIDDEN_BOOK_SLUG, id: "visible-entry")

    assert_response :success
    assert_includes response.body, "Visible Entry"
    assert_includes response.body, "Second Visible Entry"
    assert_includes response.body, "1. Visible Entry"
    assert_includes response.body, "2. Second Visible Entry"
    assert_not_includes response.body, "Hidden Entry"
  end

  test "hide access returns not found for public direct access" do
    get book_chapter_url(book_slug: HIDDEN_BOOK_SLUG, id: "hidden-entry")

    assert_response :not_found
    assert_includes response.body, "Contenuto non trovato"
  end

  test "hide access remains available to superadmin" do
    post session_url, params: { email_address: @superadmin.email_address, password: "password123" }

    get book_chapter_url(book_slug: HIDDEN_BOOK_SLUG, id: "hidden-entry")

    assert_response :success
    assert_includes response.body, "Hidden Entry"
    assert_includes response.body, "Nascosto"
  end

  test "show should return 404 for non-existent chapter" do
    get book_chapter_url(book_slug: BOOK_SLUG, id: "non-existent-chapter-slug")
    assert_response :not_found
    assert_includes response.body, "Contenuto non trovato"
  end

  test "legacy chapter route redirects to default book route" do
    get libro_chapter_url(id: "parte-1-di-cosa-parleremo-in-questo-libro")

    assert_redirected_to book_chapter_path(book_slug: BOOK_SLUG, id: "parte-1-di-cosa-parleremo-in-questo-libro")
  end

  test "unknown book redirects to default book" do
    get book_chapter_url(book_slug: "libro-che-non-esiste", id: "copertina")

    assert_redirected_to book_url(book_slug: BOOK_SLUG)
  end

  test "guida requires authenticated superadmin" do
    # Guest redirection
    get book_guida_url(book_slug: BOOK_SLUG)
    assert_redirected_to new_session_url

    # Traveler redirection
    post session_url, params: { email_address: @traveler.email_address, password: "password123" }
    get book_guida_url(book_slug: BOOK_SLUG)
    assert_redirected_to root_path
  end

  test "guida renders documentation for superadmin" do
    post session_url, params: { email_address: @superadmin.email_address, password: "password123" }
    get book_guida_url(book_slug: BOOK_SLUG)
    assert_response :success
    assert_includes response.body, "Guida alla Gestione del Libro"
    assert_includes response.body, "Frontmatter"
    assert_includes response.body, "book.yml"
    assert_includes response.body, "index.yml"
  end
end
