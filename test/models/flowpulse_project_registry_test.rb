require "test_helper"

class FlowpulseProjectRegistryTest < ActiveSupport::TestCase
  test "has one active pilot aligned with the registry" do
    registry = FlowpulseProjectRegistry.load

    assert_equal "posturacorretta", registry.dig("registry", "active_pilot")
    assert_equal "posturacorretta", FlowpulseProjectRegistry.active_project.fetch("slug")
    assert_equal 1, registry.fetch("projects").count { |project| project["status"] == "active_pilot" }
  end
end
