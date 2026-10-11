require "test_helper"

class ProblemSolvingCycleTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email_address: "cycle-model@example.com", password: "password123", password_confirmation: "password123")
    @profile = user.create_profile!(display_name: "Cycle owner", username: "cycle_owner")
  end

  test "possible solutions precede the minimum solution" do
    possible_index = ProblemSolvingCycle::STEPS.index { |key, _label| key == "possible_solutions" }
    minimum_index = ProblemSolvingCycle::STEPS.index { |key, _label| key == "minimum_solution" }

    assert_operator possible_index, :<, minimum_index
  end

  test "only one active cycle is allowed for each owner" do
    @profile.problem_solving_cycles.create!(title: "Primo", status: "active")
    duplicate = @profile.problem_solving_cycles.new(title: "Secondo", status: "active")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:status], "consente un solo problema attivo alla volta"
  end
end
