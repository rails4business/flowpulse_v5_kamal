require "yaml"

module PublicDiscovery
  class DomainCatalog
    PATH = Rails.root.join("config/data/discovery/domains.yml").freeze
    SCHEMA_VERSION = 1

    Entry = Data.define(:hostname, :content_key, :paths)

    def initialize(path: PATH)
      document = YAML.safe_load_file(path, permitted_classes: [], permitted_symbols: [], aliases: false) || {}
      raise ArgumentError, "Discovery schema non supportato" unless document["schema_version"] == SCHEMA_VERSION

      @domains = document.fetch("domains", {})
    end

    def fetch(hostname)
      host = Domain.normalize_host(hostname)
      data = @domains.fetch(host, {})
      Entry.new(hostname: host, content_key: data["content_key"].presence, paths: Array(data["paths"]).map(&:to_s))
    end

    def hostnames
      @domains.keys.sort
    end
  end
end
