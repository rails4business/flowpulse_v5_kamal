require "test_helper"

module Posturacorretta
  class LandingLineTest < ActiveSupport::TestCase
    setup do
      user = User.create!(
        email_address: "landing-line@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      profile = user.create_profile!(display_name: "Landing Line", username: "markpostura")
      RoleAssignment.create!(profile:, role: :ideatore)
      NodeCatalog.from_config("test").import!
      root = Node.find_by!(slug: "posturacorretta")
      Domain.create!(hostname: "posturacorretta.org", node: root, role_assignment: root.role_assignment, active: true, primary: true)
      LineOfferCatalog.from_config("test").import!
    end

    test "presents cumulative offers entering after the included ones" do
      line = LandingLine.find("postura-recupero")

      assert_equal "Area Massaggio e recupero", line.stations.first.title
      assert_equal "Igiene Posturale", line.stations.second.title
      assert_not_includes line.stations.map(&:slug), "area-massaggio-orientarsi"
      assert_equal [
        ["igiene-posturale", [], "area-massaggio-terapie-manuali-tecniche-corporee"],
        ["area-massaggio-recupero", ["Percorso Igiene Posturale"], nil]
      ], line.offers.map { |offer| [offer.slug, offer.included_titles, offer.entry_slug] }
    end
  end
end
