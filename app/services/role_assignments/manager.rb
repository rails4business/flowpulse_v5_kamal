module RoleAssignments
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:, context: nil)
      @actor = actor
      @context = context
    end

    def assign_operator!(profile:, brand_access:, node:, role_code:)
      RoleAssignment.transaction do
        profile.lock!
        brand_access&.lock!
        node.lock!
        authorize_actor!(profile:, node:, role_code:)
        validate_access!(profile:, brand_access:, node:, role_code:)
        assignment = RoleAssignment.find_or_initialize_by(
          profile: profile,
          role: :operator,
          role_operator: RoleDefinitions::Registry.canonical_code(role_code),
          context: node
        )
        next assignment if assignment.persisted? && assignment.effective_for_access?(brand_access)

        event = assignment.new_record? ? "assigned" : "reactivated"
        assignment.parent = node.role_assignment
        assignment.brand_access = brand_access
        assignment.assigned_by_profile = actor_profile
        assignment.status = "active"
        assignment.starts_at = Time.current
        assignment.ends_at = nil
        record_audit(assignment, event)
        assignment.save!
        assignment
      end
    end

    def revoke!(assignment)
      RoleAssignment.transaction do
        assignment.profile.lock!
        access = assignment.brand_access
        access&.lock!
        assignment.lock!
        authorize_revoke!(assignment)
        raise ArgumentError, "Il ruolo non è un incarico operativo" unless assignment.operator?
        next assignment if assignment.status == "revoked"

        assignment.status = "revoked"
        assignment.ends_at = Time.current
        record_audit(assignment, "revoked")
        assignment.save!
        access.update!(current_role_assignment: nil) if access&.current_role_assignment_id == assignment.id
        assignment
      end
    end

    private

      attr_reader :actor, :context

      def authorize_actor!(profile:, node:, role_code:)
        return if actor&.superadmin_user?
        return if AccessPolicy.can_assign_role?(
          user: actor,
          recipient_profile: profile,
          role_code: role_code,
          node: node,
          context: context
        )

        raise NotAuthorized, "Non puoi assegnare questo ruolo nel perimetro selezionato"
      end

      def authorize_revoke!(assignment)
        return if AccessPolicy.can_revoke_role?(user: actor, assignment: assignment, context: context)
        raise NotAuthorized, "Non puoi revocare questo ruolo nel perimetro selezionato"
      end

      def actor_profile
        @actor_profile ||= actor.profile || actor.with_lock do
          actor.profile || actor.create_profile!(display_name: actor.email_address.split("@").first)
        end
      end

      def record_audit(assignment, event)
        assignment.audit_log = assignment.audit_log + [{
          "event" => event, "actor_profile_id" => actor_profile.id, "at" => Time.current.iso8601(6)
        }]
      end

      def validate_access!(profile:, brand_access:, node:, role_code:)
        raise ArgumentError, "BrandAccess non attivo" unless brand_access&.active?
        raise ArgumentError, "Il BrandAccess appartiene a un altro profilo" unless brand_access.profile == profile
        raise ArgumentError, "Il Node è fuori dal BrandAccess" unless node.site_node == brand_access.brand_node
        return if RoleDefinitions::Registry.assignable_to?(role_code, brand_node: brand_access.brand_node, node: node)

        raise ArgumentError, "Ruolo non previsto per questo Brand"
      end
  end
end
