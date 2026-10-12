module PublicDiscovery
  class Projection
    SCHEMA_VERSION = 2

    def initialize(domain, policy: AccessPolicy.new)
      @domain = domain
      @policy = policy
    end

    def call
      return nil unless discoverable_domain?
      nodes = collect_children(domain.node)

      {
        "schema_version" => SCHEMA_VERSION,
        "domain" => domain_payload,
        "root_node" => node_payload(domain.node, relation: "root", url: domain_url),
        "nodes" => nodes,
        "resources" => collect_resources(nodes)
      }
    end

    private
      attr_reader :domain, :policy

      def discoverable_domain?
        policy.public_domain?(domain)
      end

      def domain_payload
        {
          "hostname" => domain.hostname,
          "url" => domain_url,
          "locale" => domain.locale,
          "title" => domain.site_title.presence || domain.node.title,
          "description" => domain.site_description.presence || domain.node.description,
          "logo_url" => domain.logo_full_url.presence || domain.logo_square_url.presence,
          "social_image_url" => domain.social_image_url.presence
        }.compact
      end

      def collect_children(parent)
        parent.children.order(:position, :title).flat_map do |node|
          next [] unless publicly_visible?(node)

          if node.bridge_node?
            bridge_payload(node, parent)
          elsif (boundary_domain = canonical_domain_for(node))
            [node_payload(node, relation: "sub_brand", parent:, url: "https://#{boundary_domain.hostname}/", boundary: true)]
          else
            [node_payload(node, relation: "child", parent:, url: node_url(node))] + collect_children(node)
          end
        end
      end

      def bridge_payload(node, parent)
        target = node.resolve_target
        return [] unless publicly_visible?(target)

        target_domain = canonical_domain_for(target)
        target_url = target_domain.present? ? "https://#{target_domain.hostname}/" : node_url(target)
        [node_payload(node, relation: "bridge", parent:, url: target_url).merge(
          "target" => {
            "id" => target.id,
            "slug" => target.slug,
            "title" => target.title,
            "url" => target_url
          }
        )]
      end

      def node_payload(node, relation:, url:, parent: nil, boundary: false)
        {
          "id" => node.id,
          "slug" => node.slug,
          "title" => node.title,
          "description" => node.description.presence,
          "node_type" => node.node_type,
          "relation" => relation,
          "parent_id" => parent&.id,
          "parent_slug" => parent&.slug,
          "url" => url,
          "boundary" => boundary,
          "updated_at" => node.updated_at&.iso8601
        }.compact
      end

      def canonical_domain_for(node)
        node.domains.active.where(canonical_host: [nil, ""]).where.not(id: domain.id)
          .order(primary: :desc, hostname: :asc).first
      end

      def publicly_visible?(node)
        policy.public_node?(node)
      end

      def collect_resources(nodes)
        projected_node_ids = [domain.node.id] + nodes.filter_map do |node|
          node["id"] if node["relation"] == "child" && !node["boundary"]
        end

        SkillProduct
          .includes(reusable_skill_node: %i[node reusable_skill])
          .where(reusable_skill_nodes: { node_id: projected_node_ids })
          .order(:title, :id)
          .filter_map do |product|
            resource_payload(product) if policy.public_skill_product?(product, domain:)
          end
      end

      def resource_payload(product)
        {
          "id" => product.id,
          "slug" => product.slug,
          "title" => product.title,
          "description" => product.data.to_h["description"].presence,
          "format" => product.format,
          "locale" => product.data.to_h["locale"].presence || domain.locale,
          "node_id" => product.node.id,
          "node_slug" => product.node.slug,
          "skill" => {
            "slug" => product.reusable_skill.slug,
            "title" => product.reusable_skill.title,
            "resource_type" => product.reusable_skill.resource_type.presence
          }.compact,
          "url" => resource_url(product),
          "published_at" => product.published_at&.iso8601,
          "updated_at" => product.updated_at&.iso8601
        }.compact
      end

      def domain_url
        "https://#{domain.hostname}/"
      end

      def node_url(node)
        "https://#{domain.hostname}/nodes/#{node.id}"
      end

      def resource_url(product)
        "https://#{domain.hostname}/resources/#{product.id}/#{product.slug}"
      end
  end
end
