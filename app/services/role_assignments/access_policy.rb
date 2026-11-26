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
      def allowed?(user:, action:, node:, context: nil)
        return true if user&.superadmin_user?

        current = current_context(user: user, context: context)
        return false unless assignment_covers_node?(current, node)

        current.capability?(ACTION_CAPABILITIES.fetch(action.to_sym, action.to_sym))
      end

      def can_create_node?(user:, parent:, context: nil)
        return true if user&.superadmin_user?

        current = current_context(user: user, context: context)
        return false unless assignment_covers_node?(current, parent) && current.capability?(:create_children)

        definition = RoleDefinitions::Registry.fetch(current.current_role_code)
        limit = definition.limits[:managed_nodes_per_brand]
        return true unless limit

        current.profile.responsible_nodes
          .where(id: current.brand.self_and_descendants.select(:id)).count < limit
      end

      def can_assign_role?(user:, recipient_profile:, role_code:, node:, context: nil)
        return true if user&.superadmin_user?

        current = current_context(user: user, context: context)
        return false unless recipient_profile && assignment_covers_node?(current, node)
        return false unless RoleDefinitions::Registry.delegation_allowed?(
          from: current.current_role_code, to: role_code, brand_node: current.brand
        )

        recipient_profile.brand_accesses.active.exists?(brand_node_id: current.brand.id)
      end

      def can_revoke_role?(user:, assignment:, context: nil)
        user&.superadmin_user? || false
      end

      # HTTP requests supply Current.access_context; jobs must pass a context.
      # The target Node never selects the actor's Brand or role implicitly.
      def current_context(user:, context: nil)
        candidate = context || Current.access_context
        return unless user && candidate&.user&.id == user.id && candidate.domain

        domain = Domain.active.find_by(id: candidate.domain.id)
        actor = User.find_by(id: user.id, registration_status: "active")
        return unless domain && actor

        fresh = AccessContext::Resolver.new(user: actor, domain: domain).resolve
        return unless fresh.brand == candidate.brand && fresh.profile == candidate.profile
        return unless fresh.current_role_assignment&.id == candidate.current_role_assignment&.id

        fresh
      end

      private

        def assignment_covers_node?(context, node)
          assignment = context&.current_role_assignment
          return false unless assignment && node.is_a?(Node) && node.site_node == context.brand
          return true if assignment.context == node

          definition = RoleDefinitions::Registry.fetch(context.current_role_code)
          definition.inheritable && node.ancestors.exists?(assignment.context_id)
        end
    end
  end
end
