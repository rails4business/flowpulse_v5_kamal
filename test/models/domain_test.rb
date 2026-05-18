require "test_helper"

class DomainTest < ActiveSupport::TestCase
  test "normalizes hostnames" do
    domain = Domain.create!(
      hostname: " POSTURACORRETTA.ORG ",
      action: "markpostura",
      locale: "it"
    )

    assert_equal "posturacorretta.org", domain.hostname
  end

  test "finds active domain by host" do
    Domain.create!(hostname: "posturacorretta.org", action: "markpostura", locale: "it")

    assert_equal "markpostura", Domain.find_for_host("POSTURACORRETTA.ORG").action
  end

  test "exports config hash" do
    Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      action: "mvp_home",
      locale: "it"
    )

    assert_equal "posturacorretta.org", Domain.export_to_hash["www.posturacorretta.org"]["canonical_host"]
  end
end
