require "test_helper"

module Posturacorretta
  class ContentRepositoryTest < ActiveSupport::TestCase
    test "hydrates a course from chapter contents through parent_id" do
      repository = ContentRepository.new
      course = repository.course_by_id("inizia-con-posturacorretta")

      assert_equal "course", course.fetch("format")
      assert_equal "free", course.fetch("access")
      assert_equal "Inizia con PosturaCorretta", course.fetch("title")
      assert_equal 7, course.fetch("chapters").size
      assert course.fetch("chapters").all? { |chapter| chapter.fetch("format") == "chapter" }
      assert course.fetch("chapters").all? { |chapter| chapter.fetch("parent_id") == course.fetch("id") }
      assert course.fetch("chapters").all? { |chapter| chapter.fetch("access") == "free" }
      assert_equal [1, 2, 3, 4, 5, 6, 7], course.fetch("chapters").map { |chapter| chapter.fetch("position") }
      assert_equal 5, course.fetch("chapters").count { |chapter| chapter.fetch("chapter_type") == "theory" }
      assert_equal 2, course.fetch("chapters").count { |chapter| chapter.fetch("chapter_type") == "practical" }
      assert_equal "brands/posturacorretta/courses/inizia-con-posturacorretta/chapters/incontro-salute-metodiche.md", course.fetch("chapters").first.fetch("content_path")
    end

    test "keeps drafts private regardless of time while allowing superadmin preview" do
      travel_to Time.zone.parse("2026-09-20 12:00") do
        assert_nil ContentRepository.new.course_by_id("muoviti-ed-esplora")
        assert_equal "Muoviti ed esplora", ContentRepository.new(include_scheduled: true).course_by_id("muoviti-ed-esplora").fetch("title")
      end

      travel_to Time.zone.parse("2026-09-21 09:01") do
        assert_nil ContentRepository.new.course_by_id("muoviti-ed-esplora")
      end
    end

    test "keeps every Academy chapter in its canonical course directory" do
      repository = ContentRepository.new(include_scheduled: true)
      courses = repository.courses

      assert_equal %w[inizia-con-posturacorretta postura-e-fisiologia muoviti-ed-esplora ascolta-gli-aspetti-vitali nutri-il-corpo regola-con-le-piante-officinali], courses.map { |course| course.fetch("slug") }

      chapters = courses.flat_map { |course| course.fetch("chapters") }
      assert chapters.all? { |chapter| chapter.fetch("content_path").start_with?("brands/posturacorretta/courses/") }
      assert chapters.all? { |chapter| Rails.root.join("config/data", chapter.fetch("content_path")).file? }
      assert_equal 7, repository.course_by_id("inizia-con-posturacorretta").fetch("chapters").size
    end

    test "rejects duplicate course slugs and duplicate chapter slugs inside a course" do
      repository = ContentRepository.new
      course = {
        "id" => "course-one", "format" => "course", "slug" => "corso",
        "status" => "published", "access" => "free"
      }
      second_course = course.merge("id" => "course-two")

      course_error = assert_raises(KeyError) do
        repository.send(:validate!, [course, second_course])
      end
      assert_includes course_error.message, "Slug course duplicati: corso"

      chapter = {
        "id" => "chapter-one", "parent_id" => "course-one", "format" => "chapter",
        "slug" => "introduzione", "status" => "published", "access" => "free"
      }
      second_chapter = chapter.merge("id" => "chapter-two")

      chapter_error = assert_raises(KeyError) do
        repository.send(:validate!, [course, chapter, second_chapter])
      end
      assert_includes chapter_error.message, "course-one/introduzione"
    end

    test "allows the same chapter slug in different courses" do
      repository = ContentRepository.new
      courses = %w[one two].map do |suffix|
        { "id" => "course-#{suffix}", "format" => "course", "slug" => "corso-#{suffix}", "status" => "published", "access" => "free" }
      end
      chapters = courses.map.with_index do |course, index|
        { "id" => "chapter-#{index}", "parent_id" => course.fetch("id"), "format" => "chapter", "slug" => "introduzione", "status" => "published", "access" => "free" }
      end

      assert_nothing_raised { repository.send(:validate!, courses + chapters) }
    end
  end
end
