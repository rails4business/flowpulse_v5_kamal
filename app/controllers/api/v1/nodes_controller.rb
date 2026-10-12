module Api
  module V1
    class NodesController < BaseController
      def index
        return unless require_public_projection!

        nodes = projected_nodes
        render_public_json(
          schema_version: PublicDiscovery::Projection::SCHEMA_VERSION,
          domain: api_domain_summary,
          count: nodes.size,
          nodes: nodes,
          links: {
            self: canonical_api_url("/api/v1/nodes"),
            domain: canonical_api_url("/api/v1/domain"),
            resources: canonical_api_url("/api/v1/resources")
          }
        )
      end

      def show
        return unless require_public_projection!

        matches = projected_nodes.select { |node| node.fetch("slug") == params[:slug].to_s }
        if matches.empty?
          return render_api_error(:not_found, "node_not_found", "Il Node non è pubblico su questo dominio.")
        end
        if matches.many?
          return render_api_error(:conflict, "ambiguous_node_slug", "Più Node pubblici usano questo slug nel dominio.")
        end

        node = matches.first
        children = public_projection.fetch("nodes").select { |candidate| candidate["parent_id"] == node["id"] }
        resources = projected_resources.select { |resource| resource["node_id"] == node["id"] }
        render_public_json(
          schema_version: PublicDiscovery::Projection::SCHEMA_VERSION,
          domain: api_domain_summary,
          node: node,
          children: children,
          resources: resources,
          links: {
            self: canonical_api_url("/api/v1/nodes/#{node.fetch('slug')}"),
            domain: canonical_api_url("/api/v1/domain"),
            nodes: canonical_api_url("/api/v1/nodes"),
            resources: canonical_api_url("/api/v1/resources")
          }
        )
      end
    end
  end
end
