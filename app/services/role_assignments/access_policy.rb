module RoleAssignments
  class AccessPolicy
    ACTION_CAPABILITIES = {
      read: :read,
      manage: :manage,
      create_node: :create_children,
      manage_access: :manage_access,
      delegate_role: :delegate_role
    }.freeze

    class << self
      def allowed?(user:, action:, node:)
        return true if user&.superadmin_user?
        return false unless user&.profile && node

        capability = ACTION_CAPABILITIES.fetch(action.to_sym, action.to_sym)
        matching_assignments(user.profile, node).any? do |assignment, definition|
          definition.capabilities.include?(capability)
        end
      end

      def can_create_node?(user:, parent:)
        return true if user&.superadmin_user?
        return false unless allowed?(user: user, action: :create_node, node: parent)

        profile = user.profile
        assignment, definition = matching_assignments(profile, parent).find do |candidate, role_definition|
          role_definition.capabilities.include?(:create_children)
        end
        return false unless assignment

        limit = definition.limits[:managed_nodes_per_brand]
        return true unless limit

        responsible_count = profile.responsible_nodes
          .where(id: assignment.brand_access.brand_node.self_and_descendants.select(:id))
          .count
        responsible_count < limit
      end

      def can_assign_role?(user:, recipient_profile:, role_code:, node:)
        return true if user&.superadmin_user?
        return false unless user&.profile && recipient_profile && node

        canonical_code = RoleDefinitions::Registry.canonical_code(role_code)
        matching_assignments(user.profile, node).any? do |assignment, definition|
          next false unless definition.delegatable_role_codes.include?(canonical_code)

          recipient_profile.brand_accesses.active.exists?(brand_node_id: assignment.brand_access.brand_node_id)
        end
      end

      private

        def matching_assignments(profile, node)
          profile.role_assignments
            .active
            .where(role: :operator)
            .includes(brand_access: :brand_node)
            .filter_map do |assignment|
              definition = RoleDefinitions::Registry.find(assignment.role_operator)
              next unless definition && assignment.brand_access&.active?
              next unless assignment_active_now?(assignment)
              next unless access_covers_node?(assignment.brand_access, node)
              next unless assignment_covers_node?(assignment, definition, node)

              [assignment, definition]
            end
        end

        def assignment_active_now?(assignment)
          return false if assignment.starts_at && assignment.starts_at > Time.current
          return false if assignment.ends_at && assignment.ends_at <= Time.current

          true
        end

        def access_covers_node?(access, node)
          node == access.brand_node || node.ancestors.exists?(access.brand_node_id)
        end

        def assignment_covers_node?(assignment, definition, node)
          return false unless assignment.context.is_a?(Node)
          return true if assignment.context == node

          definition.inheritable && node.ancestors.exists?(assignment.context_id)
        end
    end
  end
end
