module PublicDiscovery
  class DomainUrls
    def initialize(domain, catalog: DomainCatalog.new, projection: nil)
      @domain = domain
      @entry = catalog.fetch(domain.hostname)
      @projection = projection || Projection.new(domain).call
    end

    def call
      (configured_urls + article_urls + node_urls + resource_urls).uniq { |entry| entry.fetch(:loc) }
    end

    private
      attr_reader :domain, :entry, :projection

      def configured_urls
        (["/"] + entry.paths).uniq.map { |path| { loc: absolute_url(path) } }
      end

      def article_urls
        return [] if entry.content_key.blank?

        DomainContentCatalog.for_domain(entry.content_key).map do |article|
          { loc: absolute_url(article.fetch("path")), lastmod: article["publication_date"] }
        end
      end

      def node_urls
        return [] if projection.blank?

        projection.fetch("nodes").filter_map do |node|
          next unless node["relation"] == "child" && !node["boundary"]

          { loc: node.fetch("url"), lastmod: Time.iso8601(node.fetch("updated_at")).to_date }
        end
      end

      def resource_urls
        return [] if projection.blank?

        projection.fetch("resources", []).map do |resource|
          updated_at = resource["updated_at"].presence
          { loc: resource.fetch("url"), lastmod: updated_at ? Time.iso8601(updated_at).to_date : nil }.compact
        end
      end

      def absolute_url(path)
        "https://#{domain.hostname}#{path == '/' ? '/' : path}"
      end
  end
end
