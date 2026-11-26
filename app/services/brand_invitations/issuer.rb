module BrandInvitations
  class Issuer
    def initialize(actor:, context: nil)
      @actor = actor
      @context = context
    end

    def issue!(domain:, email_address:, brand_request: nil)
      domain = domain.canonical_domain_record
      BrandInvitation.transaction do
        brand_request&.lock!
        if brand_request && (!brand_request.active? || brand_request.kind != "access" ||
            brand_request.brand_node_id != domain.node_id)
          raise ArgumentError, "La richiesta non può generare un invito per questo Brand"
        end

        node = brand_request&.subject.is_a?(Node) ? brand_request.subject : domain.node
        BrandAccesses::Authorization.authorize!(actor: @actor, domain: domain, node: node, context: @context)
        brand_request&.brand_invitations&.pending&.update_all(status: "revoked", updated_at: Time.current)
        result = BrandInvitation.issue!(
          brand_node: domain.node, source_domain: domain, email_address: email_address,
          invited_by_user: @actor, brand_request: brand_request
        )
        brand_request&.update!(status: "invited", assigned_to_profile: @actor.profile)
        result
      end
    end
  end
end
