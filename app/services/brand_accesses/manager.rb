module BrandAccesses
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:, context: nil)
      @actor = actor
      @context = context
    end

    def grant!(profile:, domain:, authorization_node: nil, managed_by_grants: false)
      domain = domain&.canonical_domain_record
      node = authorization_node || domain&.node
      unless domain&.active? && node&.site_node == domain.node
        raise ArgumentError, "Il perimetro non appartiene al Brand destinatario"
      end
      BrandAccess.transaction do
        profile.lock!
        authorize_actor!(node)
        access = profile.brand_accesses.find_or_initialize_by(brand_node: domain.node)
        newly_managed = access.new_record? || !access.active?
        access.source_domain = domain
        access.status = "active"
        access.joined_at ||= Time.current
        access.grant_managed = true if newly_managed && (managed_by_grants || node != domain.node)
        access.save!
        access
      end
    end

    def revoke!(access, authorization_node: nil)
      access.with_lock do
        if authorization_node && authorization_node != access.brand_node
          raise NotAuthorized, "Per il progetto revoca la singola concessione, non l’intero BrandAccess"
        end
        authorize_actor!(access.brand_node)
        access.cancel!
      end
    end

    private

      attr_reader :actor, :context

      def authorize_actor!(node)
        return if actor&.superadmin_user?
        return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage_access, node: node, context: context)
        candidate = context || Current.access_context
        compatible_context = candidate.nil? || (candidate.user == actor && (candidate.brand.nil? || candidate.brand == node&.site_node))
        return if compatible_context && node&.site_node&.owned_by?(actor)

        raise NotAuthorized, "Non puoi gestire gli accessi in questo perimetro"
      end
  end
end
