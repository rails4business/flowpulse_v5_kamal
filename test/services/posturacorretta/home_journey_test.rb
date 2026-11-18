require "test_helper"

module Posturacorretta
  class HomeJourneyTest < ActiveSupport::TestCase
    test "numbers the selected station along the line" do
      journey = HomeJourney.new(tappa: "introduzione-postura-e-fisiologia", tab: "online")

      assert_equal 3, journey.station_number
      assert_equal 11, journey.stations.size
    end

    test "marks the online half only when every chapter of the course is completed" do
      station = HomeJourney::STATIONS.find { |item| item.fetch("slug") == "la-prima-settimana-con-posturacorretta" }
      chapters = HomeCourseCatalog.fetch(station.fetch("slug")).fetch(:chapters).map { |chapter| chapter.fetch("slug") }

      partial = HomeJourney.new(tappa: nil, tab: "online", completed_chapters: { "inizia-con-posturacorretta" => chapters.first(2) })
      complete = HomeJourney.new(tappa: nil, tab: "online", completed_chapters: { "inizia-con-posturacorretta" => chapters })

      assert_not partial.online_completed?(station)
      assert complete.online_completed?(station)
      assert_not HomeJourney.new(tappa: nil, tab: "online").online_completed?(station)
    end

    test "a retired personal path tab falls back to online data" do
      chapters = HomeCourseCatalog.fetch("la-prima-settimana-con-posturacorretta").fetch(:chapters).map { |chapter| chapter.fetch("slug") }
      journey = HomeJourney.new(tappa: nil, tab: "percorso", completed_chapters: { "inizia-con-posturacorretta" => chapters.first(3) })
      station = journey.stations.second

      assert_equal "online", journey.tab
      assert_not journey.tabs.key?("percorso")
      assert_equal({ done: 3, total: chapters.size }, journey.online_progress(station))
    end

    test "only exposes content available for the selected station" do
      journey = HomeJourney.new(tappa: "la-prima-settimana-con-posturacorretta", tab: "lezioni")

      assert journey.tabs.key?("online")
      assert journey.tabs.key?("lezioni")
      assert_equal "Lezione", journey.tabs.fetch("lezioni")
      assert_not journey.tabs.key?("insegnanti")
      assert_not journey.tabs.key?("centri")
    end
  end
end
