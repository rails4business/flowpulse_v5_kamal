require "test_helper"

class PosturacorrettaBooksControllerTest < ActionDispatch::IntegrationTest
  test "does not list the draft PosturaCorretta in un mese book publicly" do
    get posturacorretta_libri_url

    assert_response :success
    assert_select "a[href='#{book_path('postura-corretta-in-un-mese')}'][aria-label='Leggi PosturaCorretta in un mese']", count: 0
  end
end
