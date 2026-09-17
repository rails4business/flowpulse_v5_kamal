require "yaml"

module Pwa
  class SiteConfig
    ROOT = Rails.root.join("config/data/sites").freeze
    SITE_KEY_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/
    LOCAL_HOSTS = %w[localhost 127.0.0.1 ::1].freeze

    attr_reader :site_key, :settings, :scope

    def self.for(request:, domain: nil)
      candidates.filter_map do |site_key, settings|
        config = new(site_key:, settings:, request:, domain:)
        config if config.matches_request?
      end.first
    end

    def self.candidates
      return [] unless ROOT.directory?

      ROOT.children.filter_map do |directory|
        next unless directory.directory?
        next unless directory.basename.to_s.match?(SITE_KEY_PATTERN)

        path = directory.join("site.yml")
        next unless path.file?

        document = YAML.safe_load_file(path, permitted_classes: [], permitted_symbols: [], aliases: false) || {}
        settings = document.dig("site", "pwa")
        [ directory.basename.to_s, settings ] if settings.is_a?(Hash) && settings["enabled"] == true
      rescue Psych::Exception
        nil
      end
    end

    def initialize(site_key:, settings:, request:, domain: nil)
      @site_key = site_key
      @settings = settings
      @request = request
      @domain = domain
      @scope = dedicated_host? ? "/" : normalized_local_prefix
    end

    def matches_request?
      dedicated_host? || local_path_matches?
    end

    def enabled? = true
    def name = settings.fetch("name")
    def short_name = settings.fetch("short_name", name)
    def description = settings.fetch("description", "")
    def theme_color = settings.fetch("theme_color", "#ffffff")
    def background_color = settings.fetch("background_color", "#ffffff")
    def display = settings.fetch("display", "standalone")
    def icon = settings.fetch("icon")
    def version = settings.fetch("version", 1)
    def cache_name = "#{site_key.tr('_', '-')}-shell-v#{version}"
    def start_url = scope
    def offline_url = join_scope("offline")
    def manifest_url = join_scope("manifest.json")
    def service_worker_url = join_scope("service-worker.js")
    def excluded_paths = Array(settings["excluded_paths"]).map(&:to_s)

    def service_worker_scope
      scope == "/" ? "/" : "#{scope}/"
    end

    def to_manifest
      {
        name:,
        short_name:,
        description:,
        id: start_url,
        start_url:,
        scope: scope,
        display:,
        theme_color:,
        background_color:,
        icons: [
          { src: icon, type: "image/png", sizes: "512x512", purpose: "any" },
          { src: icon, type: "image/png", sizes: "512x512", purpose: "maskable" }
        ]
      }
    end

    private

    def configured_hosts
      Array(settings["hosts"]).map { |host| Domain.normalize_host(host) }
    end

    def normalized_host
      Domain.normalize_host(@request.host)
    end

    def local_request?
      LOCAL_HOSTS.include?(normalized_host)
    end

    def dedicated_host?
      configured_hosts.include?(normalized_host) || @domain&.site_key == site_key
    end

    def normalized_local_prefix
      prefix = settings.fetch("local_prefix", "/#{site_key.delete_suffix('_it')}").to_s
      normalized = "/#{prefix.sub(%r{\A/+}, '').sub(%r{/+\z}, '')}"
      normalized == "/" ? "/" : normalized
    end

    def local_path_matches?
      path = @request.path.to_s
      path == scope || path.start_with?("#{scope}/")
    end

    def join_scope(path)
      scope == "/" ? "/#{path}" : "#{scope}/#{path}"
    end
  end
end
