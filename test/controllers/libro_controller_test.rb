require "test_helper"

class LibroControllerTest < ActionDispatch::IntegrationTest
  BOOK_SLUG = "il-corpo-un-mondo-da-scoprire"

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
    assert_includes response.body, "Clicca sulla copertina per iniziare a leggere"
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
    assert_includes response.body, "Il tuo corpo ti accompagna ogni giorno"
  end

  test "toc shows visual outline numbering without changing index data" do
    get book_chapter_url(book_slug: BOOK_SLUG, id: "parte-1-di-cosa-parleremo-in-questo-libro")

    assert_response :success
    assert_includes response.body, "1. Parte I - Di cosa parleremo in questo libro"
    assert_includes response.body, "1.1. Il tuo corpo ti accompagna ogni giorno"
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
