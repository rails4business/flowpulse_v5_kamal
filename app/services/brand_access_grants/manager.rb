module BrandAccessGrants
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:, context: nil)
      @actor = actor
      @context = context
    end

    def grant!(brand_access:, node:, brand_request: nil)
      brand_access.with_lock do
        authorize!(node)
        unless brand_access.active? && node.site_node == brand_access.brand_node
          raise ArgumentError, "La concessione richiede un accesso attivo allo stesso Brand"
        end
        if brand_request && (brand_request.brand_node_id != brand_access.brand_node_id ||
            (brand_request.requester_profile_id && brand_request.requester_profile_id != brand_access.profile_id))
          raise ArgumentError, "La richiesta non appartiene a questo accesso"
        end
        grant = brand_access.grants.find_or_initialize_by(node: node)
        grant.brand_request = brand_request if brand_request
        grant.granted_by_profile = actor.profile
        grant.status = "active"
        grant.granted_at = Time.current
        grant.revoked_at = nil
        grant.save!
        grant
      end
    end

    def revoke!(grant)
      BrandAccessGrant.transaction do
        access = grant.brand_access
        access.lock!
        grant.lock!
        authorize!(grant.node)
        raise ArgumentError, "La concessione appartiene a un altro Brand" unless grant.node.site_node == access.brand_node
        grant.update!(status: "revoked", revoked_at: Time.current)
        access.cancel! if access.grant_managed? && access.grants.active.none?
      end
      grant
    end

    private

      attr_reader :actor, :context

      def authorize!(node)
        return if actor&.superadmin_user?
        return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage_access, node: node, context: context)
        candidate = context || Current.access_context
        compatible_context = candidate.nil? || (candidate.user == actor && (candidate.brand.nil? || candidate.brand == node&.site_node))
        return if compatible_context && node&.site_node&.owned_by?(actor)

        raise NotAuthorized, "Non puoi gestire le persone di questo progetto"
      end
  end
end
