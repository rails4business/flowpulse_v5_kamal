require "test_helper"

module PublicDiscovery
  class DomainCatalogTest < ActiveSupport::TestCase
    test "covers every configured canonical domain" do
      domains = Rails.application.config_for(:domains, env: "test")
      canonical_hosts = domains.filter_map do |hostname, settings|
        hostname.to_s unless settings.to_h.with_indifferent_access["canonical_host"].present?
      end.sort

      assert_equal canonical_hosts, DomainCatalog.new.hostnames
    end

    test "exposes only normalized paths for a domain" do
      entry = DomainCatalog.new.fetch("POSTURACORRETTA.ORG")

      assert_equal "posturacorretta", entry.content_key
      assert entry.paths.all? { |path| path.start_with?("/") && !path.start_with?("//") }
    end
  end
end
