require "test_helper"

module Editorial
  class ValidatorTest < ActiveSupport::TestCase
    test "validates the MarkPostura pilot" do
      result = Validator.new.validate("markpostura_it")

      assert result.valid?, result.errors.join("\n")
      assert_empty result.errors
      assert_equal 1, result.counts.fetch(:sites)
      assert_equal 2, result.counts.fetch(:pages)
      assert_equal 2, result.counts.fetch(:mounts)
    end

    test "component registry rejects unknown component types" do
      error = assert_raises(UnknownComponentError) { ComponentRegistry.fetch("partial/arbitraria") }

      assert_includes error.message, "non registrato"
    end

    test "source registry exposes only controlled source types" do
      assert_equal %w[inline shared track document], SourceRegistry.keys
      assert_equal "tracks", SourceRegistry.fetch("track").directory
      assert_raises(InvalidSourceError) { SourceRegistry.fetch("../../private") }
    end
  end
end
