module BrandAccessGrants
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:)
      @actor = actor
    end

    def grant!(brand_access:, node:, brand_request: nil)
      authorize!(node)

      grant = brand_access.grants.find_or_initialize_by(node: node)
      grant.brand_request = brand_request if brand_request
      grant.granted_by_profile = actor.profile
      grant.status = "active"
      grant.granted_at = Time.current
      grant.revoked_at = nil
      grant.save!
      grant
    end

    def revoke!(grant)
      authorize!(grant.node)

      BrandAccessGrant.transaction do
        grant.update!(status: "revoked", revoked_at: Time.current)
        access = grant.brand_access
        access.cancel! if access.grant_managed? && access.grants.active.none?
      end
      grant
    end

    private

      attr_reader :actor

      def authorize!(node)
        return if actor&.superadmin_user?
        return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage_access, node: node)
        return if node&.administered_by?(actor)

        raise NotAuthorized, "Non puoi gestire le persone di questo progetto"
      end
  end
end
