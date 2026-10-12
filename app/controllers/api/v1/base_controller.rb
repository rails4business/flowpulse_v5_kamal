module Api
  module V1
    class BaseController < ApplicationController
      allow_unauthenticated_access

      before_action :redirect_api_alias_to_canonical
      before_action :set_public_api_headers

      private
        def public_projection
          @public_projection ||= PublicDiscovery::Projection.new(current_domain).call
        end

        def require_public_projection!
          return true if public_projection.present?

          render_api_error(:not_found, "domain_not_public", "Il dominio non è disponibile nella discovery pubblica.")
          false
        end

        def render_public_json(payload)
          expires_in 5.minutes, public: true, stale_while_revalidate: 1.hour
          render json: payload if stale?(etag: payload, public: true)
        end

        def render_api_error(status, code, message)
          response.headers["Cache-Control"] = "no-store"
          render json: { error: { code:, message: } }, status:
        end

        def canonical_api_url(path)
          "https://#{public_projection.dig('domain', 'hostname')}#{path}"
        end

        def api_domain_summary
          public_projection.fetch("domain").slice("hostname", "url", "locale", "title", "description")
        end

        def projected_nodes
          [public_projection.fetch("root_node")] + public_projection.fetch("nodes")
        end

        def projected_resources
          public_projection.fetch("resources", [])
        end

        def set_public_api_headers
          response.set_header("Access-Control-Allow-Origin", "*")
          response.set_header("X-Content-Type-Options", "nosniff")
        end

        def redirect_api_alias_to_canonical
          domain = current_domain
          return if domain.blank? || local_request?
          canonical_host = domain.canonical_host.presence || domain.hostname
          return if current_domain_host == canonical_host

          redirect_to "https://#{canonical_host}#{request.fullpath}", status: :moved_permanently, allow_other_host: true
        end
    end
  end
end
