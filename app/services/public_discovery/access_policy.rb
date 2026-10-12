module PublicDiscovery
  class AccessPolicy
    PUBLIC_STATUS = "published"
    PUBLIC_VISIBILITY = "public"
    PUBLIC_SKILL_STATUSES = %w[available maintenance].freeze

    def public_domain?(domain)
      domain.present? &&
        domain.active? &&
        domain.canonical_host.blank? &&
        public_node?(domain.node)
    end

    def public_node?(node)
      public_state?(node)
    end

    def public_node_within_domain?(node, domain)
      return false unless public_domain?(domain) && node.present?

      path = node.self_and_ancestors.reverse.to_a
      root_index = path.index(domain.node)
      return false if root_index.nil?

      branch = path.drop(root_index)
      return false unless branch.all? { |candidate| public_node?(candidate) }
      return false if node != domain.node && canonical_domains(node).where.not(id: domain.id).exists?

      branch[1...-1].to_a.none? do |ancestor|
        canonical_domains(ancestor).where.not(id: domain.id).exists?
      end
    end

    def public_skill_product?(product, domain:)
      return false unless public_state?(product)

      activation = product.reusable_skill_node
      skill = product.reusable_skill
      activation&.status == "active" &&
        skill&.status.in?(PUBLIC_SKILL_STATUSES) &&
        public_node_within_domain?(product.node, domain)
    end

    def public_state?(record)
      value(record, :status) == PUBLIC_STATUS && value(record, :visibility) == PUBLIC_VISIBILITY
    end

    private

      def value(record, key)
        if record.respond_to?(key)
          record.public_send(key).to_s
        elsif record.respond_to?(:[])
          (record[key.to_s] || record[key.to_sym]).to_s
        end
      end

      def canonical_domains(node)
        node.domains.active.where(canonical_host: [nil, ""])
      end
  end
end
