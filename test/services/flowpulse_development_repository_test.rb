require "test_helper"

class FlowpulseDevelopmentRepositoryTest < ActiveSupport::TestCase
  test "loads and decorates development entries" do
    entry = FlowpulseDevelopmentRepository.new.find("registro-sviluppo-centralizzato")

    assert_equal "flowpulse", entry.fetch("owner_brand")
    assert_equal "Flowpulse", entry.fetch("owner_brand_label")
    assert_equal "verified", entry.fetch("status")
    assert_equal "registro-sviluppo-centralizzato", entry.dig("changelog", "slug")
    assert_includes entry.fetch("body"), "Flusso concordato"
    assert entry.fetch("source_path").start_with?("config/data/brands/flowpulse/development/")
  end

  test "exposes only supported workflow states" do
    assert_equal %w[proposed approved in_progress verified deployed paused], FlowpulseDevelopmentRepository::STATUSES
  end
end
