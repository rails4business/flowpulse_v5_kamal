require "test_helper"

module Performance
  class DomainBudgetCatalogTest < ActiveSupport::TestCase
    test "covers every canonical domain with valid budgets and representative paths" do
      result = DomainBudgetCatalog.new(environment: "test").validate

      assert result.valid?, result.errors.join("\n")
      assert_empty result.errors
      assert_equal 11, result.document.fetch("domains").size
      assert_equal "skipped", result.document.dig("domains", "igieneposturale.it", "baseline", "status")
      assert_includes result.warnings, "posturacorretta.org: baseline ancora da misurare"
    end
  end
end
