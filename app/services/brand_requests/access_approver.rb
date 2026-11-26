module BrandRequests
  class AccessApprover
    NotAuthorized = BrandAccesses::Authorization::NotAuthorized

    def initialize(actor:, context: nil)
      @actor = actor
      @context = context
    end

    def approve!(brand_request)
      BrandRequest.transaction do
        brand_request.lock!
        validate_request!(brand_request)
        authorization_node = authorization_node_for(brand_request)
        BrandAccesses::Authorization.authorize!(actor: actor, domain: brand_request.domain, node: authorization_node, context: context)
        access = BrandAccesses::Manager.new(actor: actor, context: context).grant!(
          profile: brand_request.requester_profile,
          domain: brand_request.domain.canonical_domain_record,
          authorization_node: authorization_node,
          managed_by_grants: true
        )
        BrandAccessGrants::Manager.new(actor: actor, context: context).grant!(
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

      attr_reader :actor, :context

      def validate_request!(brand_request)
        raise ArgumentError, "La richiesta non è una richiesta di accesso" unless brand_request.kind == "access"
        raise ArgumentError, "Collega prima la richiesta a un Profile" unless brand_request.requester_profile
        raise ArgumentError, "La richiesta è già chiusa" unless brand_request.active?
      end

      def authorization_node_for(brand_request)
        brand_request.subject.is_a?(Node) ? brand_request.subject : brand_request.brand_node
      end
  end
end
