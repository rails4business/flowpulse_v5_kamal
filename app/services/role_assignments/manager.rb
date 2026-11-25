module RoleAssignments
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:)
      @actor = actor
    end

    def assign_operator!(profile:, brand_access:, node:, role_code:)
      authorize_actor!(profile:, node:, role_code:)
      validate_access!(profile:, brand_access:, node:, role_code:)

      RoleAssignment.transaction do
        assignment = RoleAssignment.find_or_initialize_by(
          profile: profile,
          role: :operator,
          role_operator: RoleDefinitions::Registry.canonical_code(role_code),
          context: node
        )
        assignment.parent = node.role_assignment
        assignment.brand_access = brand_access
        assignment.assigned_by_profile = actor_profile
        assignment.status = "active"
        assignment.starts_at ||= Time.current
        assignment.ends_at = nil
        assignment.save!
        assignment
      end
    end

    def revoke!(assignment)
      authorize_revoke!(assignment)
      assignment.update!(status: "revoked", ends_at: Time.current)
    end

    private

      attr_reader :actor

      def authorize_actor!(profile:, node:, role_code:)
        return if actor&.superadmin_user?
        return if AccessPolicy.can_assign_role?(
          user: actor,
          recipient_profile: profile,
          role_code: role_code,
          node: node
        )

        raise NotAuthorized, "Non puoi assegnare questo ruolo nel perimetro selezionato"
      end

      def authorize_revoke!(assignment)
        return if actor&.superadmin_user?
        raise NotAuthorized, "Non puoi revocare questo ruolo nel perimetro selezionato"
      end

      def actor_profile
        actor.profile
      end

      def validate_access!(profile:, brand_access:, node:, role_code:)
        raise ArgumentError, "BrandAccess non attivo" unless brand_access&.active?
        raise ArgumentError, "Il BrandAccess appartiene a un altro profilo" unless brand_access.profile == profile
        raise ArgumentError, "Il Node è fuori dal BrandAccess" unless node == brand_access.brand_node || node.ancestors.exists?(brand_access.brand_node.id)
        return if RoleDefinitions::Registry.compatible_with_brand?(role_code, brand_access.brand_node)

        raise ArgumentError, "Ruolo non previsto per questo Brand"
      end
  end
end
