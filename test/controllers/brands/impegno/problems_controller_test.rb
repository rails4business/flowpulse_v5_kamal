require "test_helper"

module Brands
  module Impegno
    class ProblemsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = User.create!(email_address: "problems@example.com", password: "password123", password_confirmation: "password123")
        @profile = @user.create_profile!(display_name: "Problems User", username: "problems_user")
        @domain = Domain.create!(hostname: "1impegno.it", site_title: "1Impegno", active: true, primary: true)
        post session_url, params: { email_address: @user.email_address, password: "password123" }
      end

      test "keeps one active problem and moves the others to the future" do
        post impegno_problems_url, params: { problem: { title: "Primo problema", description: "Da capire" } }
        first = @profile.data_commitments.find_by!(title: "Primo problema")
        assert_equal "problem_solving", first.kind
        assert_equal "active", first.metadata["attention_state"]
        assert_equal "in_progress", first.status
        assert_not first.blocks_calendar?
        assert_nil first.starts_at

        post impegno_problems_url, params: { problem: { title: "Secondo problema" } }
        second = @profile.data_commitments.find_by!(title: "Secondo problema")
        assert_equal "future", second.metadata["attention_state"]

        patch impegno_problem_url(second), params: { operation: "focus" }
        assert_equal "future", first.reload.metadata["attention_state"]
        assert_equal "active", second.reload.metadata["attention_state"]
      end

      test "advances the process in order and resolves the problem" do
        problem = @profile.data_commitments.create!(created_by_profile: @profile, domain: @domain, title: "Problema", kind: "problem_solving", status: "in_progress", blocks_calendar: false, pricing_type: "none", contribution_type: "unpaid", metadata: { "attention_state" => "active", "completed_steps" => [] })

        patch impegno_problem_url(problem), params: { operation: "advance" }
        assert_equal ["identify"], problem.reload.metadata["completed_steps"]

        6.times { patch impegno_problem_url(problem), params: { operation: "advance" } }

        patch impegno_problem_url(problem), params: { operation: "resolve" }
        assert_equal "resolved", problem.reload.metadata["attention_state"]
        assert_equal "completed", problem.status
        assert problem.resolved_at.present?
      end
    end
  end
end
