require "test_helper"

class PosturacorrettaBooksControllerTest < ActionDispatch::IntegrationTest
  test "lists the published PosturaCorretta in un mese book" do
    get posturacorretta_libri_url

    assert_response :success
    assert_select "a[href='#{book_path('postura-corretta-in-un-mese')}'][aria-label='Leggi PosturaCorretta in un mese']"
  end
end
