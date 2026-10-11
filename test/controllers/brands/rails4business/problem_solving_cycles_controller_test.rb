require "test_helper"

module Brands
  module Rails4business
    class ProblemSolvingCyclesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "problems@example.com", password: "password123", password_confirmation: "password123")
        @profile = @user.create_profile!(display_name: "Problems User", username: "problems_user")
        post session_url, params: { email_address: @user.email_address, password: "password123" }
      end

      test "keeps one active cycle and puts later problems in backlog" do
        post rails4b_problems_url, params: { problem_solving_cycle: { title: "Primo problema", problem: "Da capire" } }
        first = @profile.problem_solving_cycles.find_by!(title: "Primo problema")
        assert_equal "active", first.status
        assert_equal 0, first.current_step

        post rails4b_problems_url, params: { problem_solving_cycle: { title: "Secondo problema" } }
        second = @profile.problem_solving_cycles.find_by!(title: "Secondo problema")
        assert_equal "backlog", second.status

        patch rails4b_problem_url(second), params: { operation: "focus" }
        assert_equal "backlog", first.reload.status
        assert_equal "active", second.reload.status
      end

      test "advances all ten steps and resolves the cycle" do
        cycle = @profile.problem_solving_cycles.create!(title: "Problema", status: "active")

        10.times { patch rails4b_problem_url(cycle), params: { operation: "advance" } }
        assert_equal 10, cycle.reload.current_step

        patch rails4b_problem_url(cycle), params: { operation: "resolve" }
        assert_equal "resolved", cycle.reload.status
        assert cycle.resolved_at.present?
      end

      test "old Impegno address redirects to Rails4Business" do
        get "/impegno/problemi"

        assert_redirected_to "/rails4b/problemi"

        get impegno_url(area: "problems")
        assert_redirected_to rails4b_problems_url
      end
    end
  end
end
