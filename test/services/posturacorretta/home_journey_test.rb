require "test_helper"

module Posturacorretta
  class HomeJourneyTest < ActiveSupport::TestCase
    test "numbers the selected station along the line" do
      journey = HomeJourney.new(tappa: "introduzione-postura-e-fisiologia", tab: "online")

      assert_equal 3, journey.station_number
      assert_equal 3, journey.stations.size
      assert_equal "Inizia con PosturaCorretta", journey.line.fetch("title")
    end

    test "uses a dedicated line and aside program for the educational path" do
      skip "In pausa (CI #249, 23/11/2026): da riallineare al nuovo lavoro su PosturaCorretta"
      journey = HomeJourney.new(tappa: "igiene-posturale", tab: "online")

      assert_equal "Recupero e terapie manuali", journey.line.fetch("title")
      assert_equal "Espressione", journey.line.fetch("area")
      assert_equal "area-massaggio-terapie-manuali-tecniche-corporee", journey.stations.first.fetch("slug")
    end

    test "previous and next cross the boundary between adjacent lines" do
      intro = HomeJourney.new(tappa: "introduzione-postura-e-fisiologia", tab: "online")
      recovery = HomeJourney.new(tappa: "area-massaggio-terapie-manuali-tecniche-corporee", tab: "online")

      assert_equal "area-massaggio-terapie-manuali-tecniche-corporee", intro.next_station.fetch("slug")
      assert_equal "introduzione-postura-e-fisiologia", recovery.previous_station.fetch("slug")
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

    test "builds the aside from direct courses and their real lessons" do
      user = User.create!(email_address: "journey-line@example.com", password: "password123", password_confirmation: "password123")
      assignment = RoleAssignment.create!(profile: user.create_profile!(display_name: "Journey Line"), role: :ideatore)
      line = Node.create!(title: "Linea di prova", slug: "linea-di-prova", view_type: "course_line", role_assignment: assignment)
      course = Node.create!(title: "Corso di prova", slug: "corso-di-prova", view_type: "course", parent: line, role_assignment: assignment)
      lesson = Node.create!(title: "Lezione · Prova", slug: "lezione-di-prova", view_type: "course_lesson", parent: course, role_assignment: assignment)

      journey = HomeJourney.new(tappa: lesson.slug, tab: "online")

      assert_equal lesson.slug, journey.station.fetch("slug")
      assert_equal line, journey.line_node
      assert_equal [course], journey.sheet_courses.map(&:node)
      assert_equal [lesson], journey.sheet_courses.first.lessons
      assert_equal lesson.slug, journey.station_for_node(lesson).fetch("slug")
    end
  end
end
