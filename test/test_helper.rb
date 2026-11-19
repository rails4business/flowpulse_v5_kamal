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

    # Corsi e capitoli PosturaCorretta come dopo il deploy (deploy:sync_catalogs): i corsi nel node
    # posturacorretta, i capitoli nei node delle loro lezioni; i node mancanti vengono creati.
    # I corsi indicati sono pubblicati come da una decisione conclusa; i capitoli restano in bozza.
    def import_posturacorretta_contents(published_courses: POSTURACORRETTA_PUBLISHED_COURSES)
      unless Node.exists?(slug: "posturacorretta")
        user = User.create!(email_address: "posturacorretta-contents@example.com", password: "password123", password_confirmation: "password123")
        owner = RoleAssignment.create!(profile: user.create_profile!(display_name: "PosturaCorretta"), role: :ideatore)
        Node.create!(title: "PosturaCorretta", slug: "posturacorretta", role_assignment: owner, node_type: :project)
      end
      brand = Node.find_by!(slug: "posturacorretta")
      lesson_slugs = Dir[Rails.root.join("config/data/brands/posturacorretta/courses/*/course.yml")].flat_map do |path|
        YAML.safe_load_file(path).fetch("contents").filter_map { |item| item["lesson_node_slug"] }
      end
      (lesson_slugs.uniq - Node.where(slug: lesson_slugs).pluck(:slug)).each do |slug|
        Node.create!(title: slug.humanize, slug:, parent: brand, view_type: "course_lesson", role_assignment: brand.role_assignment, node_type: :project)
      end
      ContentCatalog.new.import!
      Content.where(key: published_courses, format: "course").update_all(
        publication_status: "published", publication_visibility: "public", access_modes: ["free"], published_at: Time.current
      )
    end
  end
end
