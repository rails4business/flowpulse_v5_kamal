require "yaml"

module Performance
  class DomainBudgetCatalog
    PATH = Rails.root.join("config/data/performance/domain_budgets.yml").freeze
    SCHEMA_VERSION = 1
    BASELINE_STATUSES = %w[pending measured skipped].freeze
    REQUIRED_BUDGETS = %w[
      performance_score_min accessibility_score_min lcp_ms_max inp_ms_max
      cls_max ttfb_ms_max transfer_kb_max requests_max
    ].freeze

    Result = Data.define(:errors, :warnings, :document) do
      def valid? = errors.empty?
    end

    def initialize(path: PATH, domains_path: Rails.root.join("config/domains.yml"), environment: Rails.env)
      @path = Pathname(path)
      @domains_path = Pathname(domains_path)
      @environment = environment.to_s
    end

    def validate
      document = load_yaml(@path)
      errors = []
      warnings = []

      errors << "schema_version deve essere #{SCHEMA_VERSION}" unless document["schema_version"] == SCHEMA_VERSION
      defaults = document.fetch("defaults", {})
      budgets = defaults.fetch("budgets", {})
      REQUIRED_BUDGETS.each { |key| errors << "Budget predefinito mancante: #{key}" if budgets[key].nil? }
      errors << "defaults.runs deve essere almeno 1" unless defaults["runs"].to_i.positive?
      errors << "defaults.strategy deve essere mobile o desktop" unless %w[mobile desktop].include?(defaults["strategy"])

      configured_domains = document.fetch("domains", {})
      canonical_hosts = canonical_domain_hosts
      (canonical_hosts - configured_domains.keys).each { |host| errors << "Dominio canonico non coperto: #{host}" }
      (configured_domains.keys - canonical_hosts).each { |host| warnings << "Budget senza Domain canonico configurato: #{host}" }

      configured_domains.each do |host, configuration|
        validate_domain(host, configuration.to_h, errors, warnings)
      end

      Result.new(errors: errors.freeze, warnings: warnings.freeze, document: document.freeze)
    rescue Psych::Exception => error
      Result.new(errors: ["YAML non valido: #{error.message}"].freeze, warnings: [].freeze, document: {}.freeze)
    end

    private
      def load_yaml(path, aliases: false)
        YAML.safe_load_file(path, permitted_classes: [], permitted_symbols: [], aliases:) || {}
      end

      def canonical_domain_hosts
        configuration = load_yaml(@domains_path, aliases: true)
        domains = configuration.fetch(@environment, configuration.fetch("default", {}))
        domains.filter_map do |host, settings|
          attributes = settings.to_h
          next if attributes["active"] == false
          next if attributes["canonical_host"].present?

          host
        end.sort
      end

      def validate_domain(host, configuration, errors, warnings)
        baseline = configuration.fetch("baseline", {})
        status = baseline["status"].to_s
        errors << "#{host}: baseline.status non valido" unless BASELINE_STATUSES.include?(status)

        pages = Array(configuration["pages"])
        if status == "skipped"
          errors << "#{host}: una baseline saltata richiede reason" if baseline["reason"].blank?
          warnings << "#{host}: misurazione saltata — #{baseline['reason']}"
        elsif pages.empty?
          errors << "#{host}: manca almeno una pagina rappresentativa"
        end

        keys = pages.filter_map { |page| page.to_h["key"] }
        keys.tally.each { |key, count| errors << "#{host}: chiave pagina duplicata #{key}" if count > 1 }
        pages.each do |page|
          data = page.to_h
          errors << "#{host}: pagina senza key" if data["key"].blank?
          path = data["path"].to_s
          errors << "#{host}: path non valido #{path.inspect}" unless path.start_with?("/") && !path.start_with?("//")
        end

        warnings << "#{host}: baseline ancora da misurare" if status == "pending"
      end
  end
end
