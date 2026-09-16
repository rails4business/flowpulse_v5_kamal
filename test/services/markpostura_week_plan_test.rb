require "test_helper"

class MarkposturaWeekPlanTest < ActiveSupport::TestCase
  test "loads spaces from Site YAML and entries from weekly YAML" do
    data = MarkposturaWeekPlan.load.fetch("week_plan")

    assert_equal 5, data.fetch("spaces").length
    assert data.fetch("weeks").key?("2026-W38")
    assert_equal "PosturaCorretta · Gruppo", data.fetch("spaces").first.fetch("label")
  end

  test "exposes only a safely named weekly source" do
    assert MarkposturaWeekPlan.week_source("2026-W38")
    assert_nil MarkposturaWeekPlan.week_source("../../secrets")
  end
end
