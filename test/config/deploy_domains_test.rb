require "test_helper"
require "erb"
require "yaml"

class DeployDomainsTest < ActiveSupport::TestCase
  test "derives proxy and Rails hosts from every active production domain" do
    rendered = ERB.new(Rails.root.join("config/deploy.yml").read).result
    deploy = YAML.safe_load(rendered)
    domains = Rails.application.config_for(:domains, env: "production")
    expected_hosts = domains.filter_map do |hostname, settings|
      active = settings.to_h.fetch(:active, settings.to_h["active"])
      hostname.to_s unless active == false
    end.sort

    assert_equal expected_hosts, deploy.dig("proxy", "hosts")
    assert_equal expected_hosts, deploy.dig("env", "clear", "APP_HOSTS").split(",").sort
    assert_includes expected_hosts, "statodisalute.it"
    assert_includes expected_hosts, "www.statodisalute.it"
  end

  test "excludes inactive domains from deployment hosts" do
    source = Rails.root.join("config/deploy.yml").read
    assert_includes source, 'settings.to_h["active"] == false'
  end
end
