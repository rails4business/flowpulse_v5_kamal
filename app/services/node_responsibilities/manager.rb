module NodeResponsibilities
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:)
      @actor = actor
    end

    def assign!(node:, profile:, role_code:)
      authorize_actor!
      brand_access = matching_access(profile:, node:)
      raise ArgumentError, "Il profilo non ha un BrandAccess attivo compatibile" unless brand_access

      Node.transaction do
        revoke_previous_assignment!(node:, role_code:, except_profile: profile)
        assignment = RoleAssignments::Manager.new(actor: actor).assign_operator!(
          profile: profile,
          brand_access: brand_access,
          node: node,
          role_code: role_code
        )
        node.update!(responsible_profile: profile)
        assignment
      end
    end

    def remove!(node:, profile:)
      authorize_actor!
      raise ArgumentError, "Il profilo non è responsabile di questo Node" unless node.responsible_profile == profile

      Node.transaction do
        node.role_assignments_for_responsibility
          .active
          .where(profile: profile, role: :operator, role_operator: RoleDefinitions::Registry.all.map(&:code))
          .find_each do |assignment|
          RoleAssignments::Manager.new(actor: actor).revoke!(assignment)
        end
        node.update!(responsible_profile: nil)
      end
    end

    private

      attr_reader :actor

      def authorize_actor!
        return if actor&.superadmin_user?

        raise NotAuthorized, "Solo il superadmin può trasferire responsabilità in questa fase"
      end

      def matching_access(profile:, node:)
        profile.brand_accesses.active.includes(:brand_node).find do |access|
          node == access.brand_node || node.ancestors.exists?(access.brand_node_id)
        end
      end

      def revoke_previous_assignment!(node:, role_code:, except_profile:)
        canonical_code = RoleDefinitions::Registry.canonical_code(role_code)
        node.role_assignments_for_responsibility
          .where(status: "active", role: :operator, role_operator: canonical_code)
          .where.not(profile: except_profile)
          .find_each { |assignment| RoleAssignments::Manager.new(actor: actor).revoke!(assignment) }
      end
  end
end
