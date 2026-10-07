class PrivacyCatalog
  def self.for(host:)
    config = Rails.application.config_for(:privacy).to_h.deep_stringify_keys
    normalized_host = Domain.normalize_host(host)
    domain_config = config.fetch("domains", {}).fetch(normalized_host, {})
    domain_config = config.fetch("domains", {}).fetch(normalized_host.sub(/\Awww\./, ""), {}) if domain_config.empty?

    categories = config.fetch("categories", {}).deep_merge(domain_config.fetch("categories", {}))
    {
      "version" => config.fetch("version"),
      "prompt" => domain_config.fetch("prompt", config.fetch("prompt", false)),
      "policy_path" => domain_config["policy_path"].presence || config["policy_path"].presence,
      "categories" => categories
    }
  end
end
