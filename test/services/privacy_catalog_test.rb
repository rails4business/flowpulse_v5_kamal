require "test_helper"

class PrivacyCatalogTest < ActiveSupport::TestCase
  test "enables only declared optional services for a domain" do
    config = PrivacyCatalog.for(host: "www.corpoecoscienza.org")

    assert config.fetch("prompt")
    assert_equal "/corpo-e-coscienza/privacy", config.fetch("policy_path")
    assert config.dig("categories", "necessary", "enabled")
    assert config.dig("categories", "functionality", "enabled")
    assert_equal ["Leaflet", "OpenStreetMap"], config.dig("categories", "functionality", "services")
    assert_not config.dig("categories", "analytics", "enabled")
    assert_not config.dig("categories", "marketing", "enabled")
  end

  test "does not prompt domains with necessary tools only" do
    config = PrivacyCatalog.for(host: "example.test")

    assert_not config.fetch("prompt")
    assert_nil config.fetch("policy_path")
    assert config.dig("categories", "necessary", "enabled")
  end
end
