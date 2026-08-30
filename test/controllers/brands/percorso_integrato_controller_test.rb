require "test_helper"

module Brands
  class PercorsoIntegratoControllerTest < ActionDispatch::IntegrationTest
    test "shows the standalone Percorso Integrato brand" do
      get percorso_integrato_path

      assert_response :success
      assert_select "h1", text: "Costruisci un percorso personale, leggibile e coordinato."
      assert_select "nav[aria-label='Navigazione Percorso Integrato']"
      assert_select "#come-funziona"
      assert_select "#ruoli"
      assert_select "#inizia"
      assert_select "a[href^='https://wa.me/393792891488']", text: "Scrivi su WhatsApp"
    end

    test "redirects the former PosturaCorretta path to the standalone brand" do
      get posturacorretta_percorso_path

      assert_redirected_to percorso_integrato_path
      assert_response :moved_permanently
    end

    test "keeps professionals and places inside Percorso Integrato" do
      get percorso_integrato_professionals_path
      assert_response :success
      assert_select "h1", text: "Professionisti del Percorso Integrato"
      assert_select "a[href='#{percorso_integrato_professional_path('giovanni-damiata')}']"

      get percorso_integrato_professional_path("giovanni-damiata")
      assert_response :success
      assert_select "h1", text: "Giovanni Damiata"

      get percorso_integrato_places_path
      assert_response :success
      assert_select "h1", text: "Luoghi del Percorso Integrato"
      assert_select "h2", text: "Studio Movimento"
      assert_select "h2", text: "Giardino del Corpo", count: 0
    end
  end
end
