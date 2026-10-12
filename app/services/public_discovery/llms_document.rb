module PublicDiscovery
  class LlmsDocument
    def initialize(domain, projection: Projection.new(domain).call)
      @domain = domain
      @projection = projection
    end

    def call
      raise ArgumentError, "Dominio non disponibile nella discovery pubblica" if projection.blank?

      lines = ["# #{domain_title}", ""]
      lines << "> #{summary}"
      lines.concat(["", "Lingua: #{domain.locale}"])
      append_instructions(lines)
      append_primary_links(lines)
      append_public_nodes(lines)
      append_public_resources(lines)
      "#{lines.join("\n").rstrip}\n"
    end

    private

      attr_reader :domain, :projection

      def domain_title
        projection.dig("domain", "title").to_s.strip
      end

      def summary
        domain.llms_summary.presence || projection.dig("domain", "description").presence ||
          "Informazioni pubbliche di #{domain_title}."
      end

      def append_instructions(lines)
        return if domain.llms_instructions.blank?

        lines.concat(["", "## Indicazioni", "", domain.llms_instructions])
      end

      def append_primary_links(lines)
        base_url = projection.dig("domain", "url").to_s.delete_suffix("/")
        lines.concat([
          "", "## Risorse principali", "",
          "- [Sito ufficiale](#{base_url}/): pagina principale del dominio.",
          "- [Sitemap](#{base_url}/sitemap.xml): elenco degli URL pubblici.",
          "- [API del dominio](#{base_url}/api/v1/domain): identità e struttura pubblica del dominio.",
          "- [API dei Node](#{base_url}/api/v1/nodes): Node pubblici esposti in formato JSON.",
          "- [API delle risorse](#{base_url}/api/v1/resources): prodotti pubblici delle Skill attive."
        ])
      end

      def append_public_nodes(lines)
        nodes = [projection.fetch("root_node")] + projection.fetch("nodes")
        return if nodes.empty?

        lines.concat(["", "## Struttura pubblica", ""])
        nodes.each do |node|
          description = node["description"].presence
          suffix = description ? ": #{description}" : ""
          lines << "- [#{node.fetch('title')}](#{node.fetch('url')})#{suffix}"
        end
      end

      def append_public_resources(lines)
        resources = projection.fetch("resources", [])
        return if resources.empty?

        lines.concat(["", "## Risorse pubbliche", ""])
        resources.each do |resource|
          description = resource["description"].presence
          suffix = description ? ": #{description}" : ""
          lines << "- [#{resource.fetch('title')}](#{resource.fetch('url')})#{suffix}"
        end
      end
  end
end
