module Api
  module V1
    class DomainsController < BaseController
      def show
        return unless require_public_projection!

        render_public_json(
          schema_version: PublicDiscovery::Projection::SCHEMA_VERSION,
          domain: public_projection.fetch("domain"),
          root_node: public_projection.fetch("root_node"),
          node_count: projected_nodes.size,
          resource_count: projected_resources.size,
          links: {
            self: canonical_api_url("/api/v1/domain"),
            nodes: canonical_api_url("/api/v1/nodes"),
            resources: canonical_api_url("/api/v1/resources")
          }
        )
      end
    end
  end
end
