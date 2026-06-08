require "test_helper"

class DomainTest < ActiveSupport::TestCase
  test "normalizes hostnames" do
    domain = Domain.create!(
      hostname: " POSTURACORRETTA.ORG ",
      target_controller: "landing",
      target_action: "posturacorretta",
      locale: "it"
    )

    assert_equal "posturacorretta.org", domain.hostname
  end

  test "normalizes hostnames with ports" do
    domain = Domain.create!(
      hostname: " POSTURACORRETTA.ORG:443 ",
      target_controller: "landing",
      target_action: "posturacorretta",
      locale: "it"
    )

    assert_equal "posturacorretta.org", domain.hostname
  end

  test "finds active domain by host" do
    Domain.create!(hostname: "posturacorretta.org", target_controller: "landing", target_action: "posturacorretta", locale: "it")

    assert_equal "posturacorretta", Domain.find_for_host("POSTURACORRETTA.ORG").target_action
  end

  test "exports config hash" do
    Domain.create!(
      hostname: "www.posturacorretta.org",
      canonical_host: "posturacorretta.org",
      locale: "it"
    )

    assert_equal "posturacorretta.org", Domain.export_to_hash["www.posturacorretta.org"]["canonical_host"]
  end
end
