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

    # Corsi e capitoli PosturaCorretta come dopo il deploy (deploy:sync_catalogs): Content importati
    # dai course.yml nel node posturacorretta, che viene creato se il test non l'ha già fatto.
    # I corsi indicati sono pubblicati come da una decisione conclusa; i capitoli restano in bozza.
    def import_posturacorretta_contents(published_courses: POSTURACORRETTA_PUBLISHED_COURSES)
      unless Node.exists?(slug: "posturacorretta")
        user = User.create!(email_address: "posturacorretta-contents@example.com", password: "password123", password_confirmation: "password123")
        owner = RoleAssignment.create!(profile: user.create_profile!(display_name: "PosturaCorretta"), role: :ideatore)
        Node.create!(title: "PosturaCorretta", slug: "posturacorretta", role_assignment: owner, node_type: :project)
      end
      ContentCatalog.new.import!
      Content.where(key: published_courses, format: "course").update_all(
        publication_status: "published", publication_visibility: "public", access_modes: ["free"], published_at: Time.current
      )
    end
  end
end
