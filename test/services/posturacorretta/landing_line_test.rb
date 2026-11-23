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
      MetroLineCatalog.from_config("test").import!
    end

    test "presents the ordered stations" do
      line = LandingLine.find("postura-recupero")

      assert_equal "Inizia il percorso", line.stations.first.title
      assert_equal "Inizia il percorso", line.stations.second.title
      assert_equal "La prima settimana con PosturaCorretta", line.stations.third.title
      assert_not_includes line.stations.map(&:slug), "area-massaggio-orientarsi"
    end
  end
end
