class DomainContentCatalog
  CONTENT_ROOT = Rails.root.join("config/data").freeze
  BRAND_CONTENT_ROOT = CONTENT_ROOT.join("brands").freeze

  DOMAIN_SETTINGS = {
    "flowpulse" => {
      "name" => "Flowpulse",
      "host" => "flowpulse.net",
      "article_path" => "/flowpulse/contenuti/%{slug}"
    },
    "posturacorretta" => {
      "name" => "PosturaCorretta",
      "host" => "posturacorretta.org",
      "article_path" => "/posturacorretta/contenuti/%{slug}"
    },
    "markpostura" => {
      "name" => "Mark Postura",
      "host" => "markpostura.it",
      "article_path" => "/markpostura/contenuti/%{slug}"
    },
    "rails4b" => {
      "name" => "Rails4Business",
      "host" => "rails4b.com",
      "article_path" => "/rails4b/contenuti/%{slug}"
    }
  }.freeze

  class << self
    def for_domain(domain_key, include_scheduled: false)
      all(include_scheduled: include_scheduled).select { |article| article.fetch("domain_key") == domain_key.to_s }
    end

    def for_author(username, include_scheduled: false)
      normalized_username = username.to_s.delete_prefix("@").downcase
      all(include_scheduled: include_scheduled).select do |article|
        article.fetch("author", "").to_s.delete_prefix("@").downcase == normalized_username
      end
    end

    def find(domain_key, slug, include_scheduled: false)
      for_domain(domain_key, include_scheduled:).find { |article| article.fetch("slug") == slug.to_s }
    end

    def all(include_scheduled: false)
      catalog_paths.flat_map { |path| load_catalog(path, include_scheduled:) }
                   .uniq { |article| [article.fetch("domain_key"), article.fetch("slug")] }
                   .sort_by { |article| article_sort_key(article) }
    end

    private

      def catalog_paths
        Dir.glob(CONTENT_ROOT.join("*/contenuti/catalog.yml")).sort
      end

      def load_catalog(path, include_scheduled:)
        domain_key = Pathname(path).relative_path_from(CONTENT_ROOT).each_filename.first
        raw = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}

        catalog_articles(raw).filter_map do |article, category_key, category|
          decorate_article(article, domain_key, category_key, category, include_scheduled:)
        end
      rescue Psych::SyntaxError => error
        Rails.logger.error("Catalogo contenuti non valido #{path}: #{error.message}")
        []
      end

      def catalog_articles(raw)
        if raw["articles"].is_a?(Array)
          raw.fetch("articles").map { |article| [article, nil, {}] }
        elsif raw["items"].is_a?(Array)
          raw.fetch("items").map { |article| [article, nil, {}] }
        else
          raw.flat_map do |category_key, category|
            next [] unless category.is_a?(Hash) && category["articles"].is_a?(Array)

            category.fetch("articles").map { |article| [article, category_key, category] }
          end
        end
      end

      def decorate_article(article, domain_key, category_key, category, include_scheduled:)
        return unless article.is_a?(Hash) && article["slug"].present?

        article = article.merge(canonical_content_metadata(domain_key, article.fetch("slug")))
        source = article["source"].presence || discover_dated_source(domain_key, article.fetch("slug")) || "articoli/#{article.fetch('slug')}.md"
        publication_date = parse_date(article["publication_at"]) || publication_date_from_source(source)
        scheduled = publication_date.present? && publication_date > Date.current
        return if scheduled && !include_scheduled

        settings = DOMAIN_SETTINGS.fetch(domain_key, default_domain_settings(domain_key))
        article_path = format(settings.fetch("article_path"), slug: article.fetch("slug"))
        article_url = article["url"].presence || "https://#{settings.fetch('host')}#{article_path}"
        brand_source = article["brand_source"].presence
        content_root = brand_source ? BRAND_CONTENT_ROOT.join(domain_key, "contents").cleanpath : CONTENT_ROOT.join(domain_key, "contenuti").cleanpath
        content_path = brand_source ? content_root.join(brand_source).cleanpath : content_root.join(source).cleanpath
        content_path = nil unless content_path.to_s.start_with?("#{content_root}/")

        article.merge(
          "author" => article["author"].to_s.delete_prefix("@").downcase,
          "domain_key" => domain_key,
          "domain_name" => settings.fetch("name"),
          "domain_host" => settings.fetch("host"),
          "category_key" => category_key,
          "category_name" => category["label"] || article["eyebrow"] || category_key.to_s.humanize.presence,
          "publication_date" => publication_date,
          "publication_label" => publication_date&.strftime("%d/%m/%Y"),
          "scheduled" => scheduled,
          "content_path" => content_path&.to_s,
          "path" => article_path,
          "url" => article_url
        )
      end

      def default_domain_settings(domain_key)
        {
          "name" => domain_key.to_s.humanize,
          "host" => domain_key.to_s,
          "article_path" => "/contenuti/%{slug}"
        }
      end

      def parse_date(value)
        Date.iso8601(value.to_s) if value.present?
      rescue ArgumentError
        nil
      end

      def publication_date_from_source(source)
        match = File.basename(source.to_s).match(/\A(\d{4}-\d{2}-\d{2})-/)
        parse_date(match&.[](1))
      end

      def discover_dated_source(domain_key, slug)
        pattern = CONTENT_ROOT.join(domain_key, "contenuti", "articoli", "*", "????-??-??-#{slug}.md")
        path = Dir.glob(pattern).sort.last
        return unless path

        Pathname(path).relative_path_from(CONTENT_ROOT.join(domain_key, "contenuti")).to_s
      end

      def canonical_content_metadata(domain_key, slug)
        root = BRAND_CONTENT_ROOT.join(domain_key, "contents")
        return {} unless root.directory?

        path = Dir.glob(root.join("*/content.yml")).sort.find do |candidate|
          data = YAML.safe_load_file(candidate, permitted_classes: [], aliases: false) || {}
          data["slug"].to_s == slug.to_s
        rescue Psych::SyntaxError
          false
        end
        return {} unless path

        data = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
        data["brand_source"] ||= Pathname(path).dirname.join("content.md").relative_path_from(root).to_s
        data
      rescue Psych::SyntaxError => error
        Rails.logger.error("Contenuto canonico non valido #{domain_key}/#{slug}: #{error.message}")
        {}
      end

      def article_sort_key(article)
        publication_date = article["publication_date"]
        publication_date ? [0, -publication_date.jd, article.fetch("title", "")] : [1, 0, article.fetch("title", "")]
      end
  end
end
