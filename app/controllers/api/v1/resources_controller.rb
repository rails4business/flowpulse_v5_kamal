module Api
  module V1
    class ResourcesController < BaseController
      def index
        return unless require_public_projection!

        resources = public_projection.fetch("resources", [])
        render_public_json(
          schema_version: PublicDiscovery::Projection::SCHEMA_VERSION,
          domain: api_domain_summary,
          count: resources.size,
          resources:,
          links: {
            self: canonical_api_url("/api/v1/resources"),
            domain: canonical_api_url("/api/v1/domain"),
            nodes: canonical_api_url("/api/v1/nodes")
          }
        )
      end

      def show
        return unless require_public_projection!

        resource = public_projection.fetch("resources", []).find { |item| item.fetch("id").to_s == params[:id].to_s }
        return render_api_error(:not_found, "resource_not_found", "La risorsa non è pubblica su questo dominio.") if resource.blank?

        product = SkillProduct.find(resource.fetch("id"))
        render_public_json(
          schema_version: PublicDiscovery::Projection::SCHEMA_VERSION,
          domain: api_domain_summary,
          resource: resource.merge("body" => product.body.presence),
          links: {
            self: canonical_api_url("/api/v1/resources/#{product.id}"),
            html: resource.fetch("url"),
            domain: canonical_api_url("/api/v1/domain"),
            node: canonical_api_url("/api/v1/nodes/#{resource.fetch('node_slug')}")
          }
        )
      end
    end
  end
end
