module NodeManagement
  class Manager
    class NotAuthorized < StandardError; end

    def initialize(actor:)
      @actor = actor
    end

    def create_child!(parent:, attributes:)
      authorize_create!(parent)

      Node.transaction do
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
      authorize_manage!(node)
      node.update!(permitted_attributes(attributes))
      node
    end

    private

      attr_reader :actor

      def authorize_create!(parent)
        return if RoleAssignments::AccessPolicy.can_create_node?(user: actor, parent: parent)

        raise NotAuthorized, "Non puoi creare altri Node in questo perimetro"
      end

      def authorize_manage!(node)
        return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage, node: node)

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
