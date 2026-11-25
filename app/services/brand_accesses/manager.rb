module BrandAccesses
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:)
      @actor = actor
    end

    def grant!(profile:, domain:, authorization_node: nil, managed_by_grants: false)
      authorize_actor!(authorization_node || domain&.node)
      raise ArgumentError, "Il dominio non è collegato a un Brand" unless domain&.node

      access = profile.brand_accesses.find_or_initialize_by(brand_node: domain.node)
      newly_managed = access.new_record? || !access.active?
      access.source_domain = domain
      access.status = "active"
      access.joined_at = Time.current
      access.grant_managed = true if managed_by_grants && newly_managed
      access.save!
      access
    end

    def revoke!(access, authorization_node: nil)
      authorize_actor!(authorization_node || access.brand_node)
      access.cancel!
    end

    private

      attr_reader :actor

      def authorize_actor!(node)
        return if actor&.superadmin_user?
        return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage_access, node: node)
        return if node&.administered_by?(actor)

        raise NotAuthorized, "Non puoi gestire gli accessi in questo perimetro"
      end
  end
end
