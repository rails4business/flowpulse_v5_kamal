require "test_helper"

class DedicatedDomainTest < ActiveSupport::TestCase
  test "finds configured domain by hostname" do
    domain = DedicatedDomain.find("POSTURACORRETTA.IT")

    assert_equal "posturacorretta.it", domain.hostname
    assert_equal "markpostura", domain.action
    assert_equal "it", domain.locale
  end

  test "finds canonical alias" do
    domain = DedicatedDomain.find("www.posturacorretta.it")

    assert_equal "posturacorretta.it", domain.canonical_host
  end

  test "returns nil for unknown host" do
    assert_nil DedicatedDomain.find("unknown.test")
  end
end
