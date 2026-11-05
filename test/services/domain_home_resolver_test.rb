require "test_helper"

class DomainHomeResolverTest < ActiveSupport::TestCase
  test "auto preserves the current precedence" do
    domain = Domain.new(
      hostname: "auto.example",
      site_key: "site-key",
      target_controller: "landing",
      target_action: "flowpulse",
      node: Node.new
    )

    assert_equal :site, DomainHomeResolver.new(domain, site_key: "site-key").call
    assert_equal :target, DomainHomeResolver.new(domain).call

    domain.target_controller = nil
    domain.target_action = nil
    assert_equal :node, DomainHomeResolver.new(domain).call
  end

  test "explicit modes select only their configured renderer" do
    domain = Domain.new(
      hostname: "explicit.example",
      target_controller: "landing",
      target_action: "flowpulse",
      node: Node.new
    )

    domain.home_mode = "node"
    assert_equal :node, DomainHomeResolver.new(domain, site_key: "site-key").call

    domain.home_mode = "target"
    assert_equal :target, DomainHomeResolver.new(domain, site_key: "site-key").call

    domain.home_mode = "site"
    assert_equal :site, DomainHomeResolver.new(domain, site_key: "site-key").call
  end

  test "explicit modes reject missing configuration instead of falling through" do
    domain = Domain.new(hostname: "missing.example", home_mode: "node")

    assert_equal :misconfigured, DomainHomeResolver.new(domain).call

    domain.home_mode = "site"
    assert_equal :misconfigured, DomainHomeResolver.new(domain).call

    domain.home_mode = "target"
    assert_equal :misconfigured, DomainHomeResolver.new(domain).call
  end
end
