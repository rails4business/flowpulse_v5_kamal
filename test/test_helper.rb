ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # I corsi che i course.yml davano pubblicati prima che lo stato passasse agli impegni.
    POSTURACORRETTA_PUBLISHED_COURSES = %w[
      inizia-con-posturacorretta introduzione-percorso-integrato-posturacorretta il-tuo-stato-di-salute
      percorso-integrato postura-e-fisiologia corpo-come-un-giardino
    ].freeze

    # Corsi e capitoli come dopo il deploy (deploy:sync_catalogs): i corsi nel node del brand, i capitoli
    # nei node delle loro lezioni; i node che il test non ha già creato vengono creati qui.
    # I corsi PosturaCorretta indicati sono pubblicati come da una decisione conclusa; il resto è in bozza.
    def import_posturacorretta_contents(published_courses: POSTURACORRETTA_PUBLISHED_COURSES)
      Dir[Rails.root.join("config/data/brands/*/courses/*/course.yml")].sort.each do |path|
        items = YAML.safe_load_file(path).fetch("contents")
        brand_slug = items.find { |item| item["format"] == "course" }&.dig("publisher_node_slug") || Pathname(path).each_filename.to_a[-4]
        brand = Node.find_by(slug: brand_slug) || create_catalog_test_node(brand_slug)
        items.filter_map { |item| item["lesson_node_slug"] }.uniq.each do |slug|
          create_catalog_test_node(slug, parent: brand, view_type: "course_lesson") unless Node.exists?(slug:)
        end
      end
      Dir[Rails.root.join("config/data/brands/*/contents/*/content.yml")].sort.each do |path|
        folder_slug = Pathname(path).each_filename.to_a[-4]
        folder = Node.find_by(slug: folder_slug) || create_catalog_test_node(folder_slug)
        publisher_slug = YAML.safe_load_file(path)["publisher_node_slug"]
        create_catalog_test_node(publisher_slug, parent: folder) if publisher_slug.present? && !Node.exists?(slug: publisher_slug)
      end
      ContentCatalog.new.import!
      Content.where(key: published_courses, format: "course").update_all(
        publication_status: "published", publication_visibility: "public", access_modes: ["free"], published_at: Time.current
      )
    end

    def create_catalog_test_node(slug, parent: nil, view_type: "default")
      role_assignment = parent&.role_assignment || begin
        user = User.create!(email_address: "#{slug}-contents@example.com", password: "password123", password_confirmation: "password123")
        RoleAssignment.create!(profile: user.create_profile!(display_name: slug.humanize), role: :ideatore)
      end
      Node.create!(title: slug.humanize, slug:, parent:, view_type:, role_assignment:, node_type: :project)
    end
  end
end
