class DedicatedDomain
  attr_reader :hostname, :config

  def self.find(hostname)
    normalized_hostname = normalize_hostname(hostname)
    domain_config = configs[normalized_hostname] || configs[normalized_hostname.to_sym]
    return unless domain_config

    new(normalized_hostname, domain_config)
  end

  def self.configs
    Rails.application.config_for(:dedicated_domains).to_h.with_indifferent_access
  end
  def self.normalize_hostname(hostname)
    hostname.to_s.downcase.strip
  end

  def initialize(hostname, config)
    @hostname = self.class.normalize_hostname(hostname)
    @config = config.with_indifferent_access
  end

  def canonical?
    canonical_host.blank?
  end

  def canonical_host
    config[:canonical_host].presence
  end

  def action
    config[:action].presence || "mvp_home"
  end

  def locale
    config[:locale].presence || I18n.default_locale.to_s
  end
end
