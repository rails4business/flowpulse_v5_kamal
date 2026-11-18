require "test_helper"

module Posturacorretta
  class ContentRepositoryTest < ActiveSupport::TestCase
    setup { import_posturacorretta_contents }

    test "hydrates a course from chapter contents through parent_id" do
      repository = ContentRepository.new
      course = repository.course_by_id("inizia-con-posturacorretta")

      assert_equal "course", course.fetch("format")
      assert_equal "free", course.fetch("access")
      assert_equal "La prima settimana con PosturaCorretta", course.fetch("title")
      assert_equal 7, course.fetch("chapters").size
      assert course.fetch("chapters").all? { |chapter| chapter.fetch("format") == "chapter" }
      assert course.fetch("chapters").all? { |chapter| chapter.fetch("parent_id") == course.fetch("id") }
      assert course.fetch("chapters").all? { |chapter| chapter.fetch("access") == "free" }
      assert_equal [1, 2, 3, 4, 5, 6, 7], course.fetch("chapters").map { |chapter| chapter.fetch("position") }
      assert course.fetch("chapters").none? { |chapter| chapter.key?("chapter_type") }
      assert_equal "brands/posturacorretta/courses/inizia-con-posturacorretta/chapters/trama-postura-fisiologia.md", course.fetch("chapters").first.fetch("content_path")
    end

    test "keeps drafts private regardless of time while allowing superadmin preview" do
      travel_to Time.zone.parse("2026-09-20 12:00") do
        assert_nil ContentRepository.new.course_by_id("muoviti-ed-esplora")
        assert_equal "Postura e consapevolezza", ContentRepository.new(include_scheduled: true).course_by_id("muoviti-ed-esplora").fetch("title")
      end

      travel_to Time.zone.parse("2026-09-21 09:01") do
        assert_nil ContentRepository.new.course_by_id("muoviti-ed-esplora")
      end
    end

    test "keeps every Academy chapter in its canonical course directory" do
      repository = ContentRepository.new(include_scheduled: true)
      courses = repository.courses

      assert_equal %w[
        inizia-con-posturacorretta
        introduzione-percorso-integrato-posturacorretta
        il-tuo-stato-di-salute
        percorso-integrato
        postura-e-fisiologia
        muoviti-ed-esplora
        corpo-come-un-giardino
        ascolta-gli-aspetti-vitali
        nutri-il-corpo
        regola-con-le-piante-officinali
      ], courses.map { |course| course.fetch("slug") }

      chapters = courses.flat_map { |course| course.fetch("chapters") }
      assert chapters.all? { |chapter| chapter.fetch("content_path").start_with?("brands/posturacorretta/courses/") }
      assert chapters.all? { |chapter| Rails.root.join("config/data", chapter.fetch("content_path")).file? }
      assert_equal 7, repository.course_by_id("inizia-con-posturacorretta").fetch("chapters").size
    end
  end
end
