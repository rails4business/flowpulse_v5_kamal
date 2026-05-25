require "test_helper"

class DomainTest < ActiveSupport::TestCase
  test "normalizes hostnames" do
    domain = Domain.create!(
      hostname: " POSTURACORRETTA.ORG ",
      action: "posturacorretta",
      locale: "it"
    )

    assert_equal "posturacorretta.org", domain.hostname
  end

  test "finds active domain by host" do
    Domain.create!(hostname: "posturacorretta.org", action: "posturacorretta", locale: "it")

    assert_equal "posturacorretta", Domain.find_for_host("POSTURACORRETTA.ORG").action
  end

  test "exports config hash" do
    Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      action: "posturacorretta",
      locale: "it"
    )

    assert_equal "posturacorretta.org", Domain.export_to_hash["www.posturacorretta.org"]["canonical_host"]
  end
end
