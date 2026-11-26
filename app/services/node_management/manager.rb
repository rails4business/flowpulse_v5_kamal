module NodeManagement
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:, context: nil)
      @actor = actor
      @context = context
    end

    def create_child!(parent:, attributes:)
      Node.transaction do
        actor.profile&.lock!
        parent.lock!
        authorize_create!(parent)
        Node.create!(
          permitted_attributes(attributes).merge(
            parent: parent,
            role_assignment: parent.role_assignment,
            node_type: :project,
            responsible_profile: responsible_profile_for(parent)
          )
        )
      end
    end

    def update!(node:, attributes:)
      node.with_lock do
        authorize_manage!(node)
        node.update!(permitted_attributes(attributes))
        node
      end
    end

    private

      attr_reader :actor, :context

      def authorize_create!(parent)
        return if RoleAssignments::AccessPolicy.can_create_node?(user: actor, parent: parent, context: context)

        raise NotAuthorized, "Non puoi creare altri Node in questo perimetro"
      end

      def authorize_manage!(node)
        return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage, node: node, context: context)

        raise NotAuthorized, "Non puoi modificare questo Node"
      end

      def responsible_profile_for(parent)
        return parent.responsible_profile if actor.superadmin_user?

        actor.profile
      end

      def permitted_attributes(attributes)
        attributes.to_h.symbolize_keys.slice(:title, :description, :status, :visibility)
      end
  end
end
