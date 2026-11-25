module BrandRequests
  class AccessApprover
    class NotAuthorized < StandardError; end

    def initialize(actor:)
      @actor = actor
    end

    def approve!(brand_request)
      validate_request!(brand_request)
      authorization_node = authorization_node_for(brand_request)
      authorize!(brand_request, authorization_node)

      BrandRequest.transaction do
        access = BrandAccesses::Manager.new(actor: actor).grant!(
          profile: brand_request.requester_profile,
          domain: brand_request.domain.canonical_domain_record,
          authorization_node: authorization_node,
          managed_by_grants: true
        )
        BrandAccessGrants::Manager.new(actor: actor).grant!(
          brand_access: access,
          node: authorization_node,
          brand_request: brand_request
        )
        brand_request.update!(
          status: "accepted",
          assigned_to_profile: actor.profile,
          resolved_at: Time.current
        )
        access
      end
    end

    private

      attr_reader :actor

      def validate_request!(brand_request)
        raise ArgumentError, "La richiesta non è una richiesta di accesso" unless brand_request.kind == "access"
        raise ArgumentError, "Collega prima la richiesta a un Profile" unless brand_request.requester_profile
        raise ArgumentError, "La richiesta è già chiusa" unless brand_request.active?
      end

      def authorization_node_for(brand_request)
        brand_request.subject.is_a?(Node) ? brand_request.subject : brand_request.brand_node
      end

      def authorize!(brand_request, authorization_node)
        return if actor&.superadmin_user?
        return if brand_request.brand_node.administered_by?(actor)
        return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage_access, node: authorization_node)

        raise NotAuthorized, "Non puoi approvare questa richiesta"
      end
  end
end
