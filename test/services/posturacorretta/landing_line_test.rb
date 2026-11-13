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

      assert_equal "Introduzione al Percorso Integrato", line.stations.first.title
      assert_equal "Introduzione al Percorso Integrato", line.stations.second.title
      assert_equal "La prima settimana con PosturaCorretta", line.stations.third.title
      assert_not_includes line.stations.map(&:slug), "area-massaggio-orientarsi"
      assert_equal [
        ["prima-settimana-posturacorretta", [], "introduzione-al-percorso-integrato"],
        ["igiene-posturale", ["La prima settimana con PosturaCorretta"], "introduzione-postura-e-fisiologia"],
        ["area-massaggio-recupero", ["La prima settimana con PosturaCorretta", "Percorso Igiene Posturale"], nil]
      ], line.offers.map { |offer| [offer.slug, offer.included_titles, offer.entry_slug] }
    end
  end
end
