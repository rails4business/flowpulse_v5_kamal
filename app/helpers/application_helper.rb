module ApplicationHelper
  PUBLIC_FULL_WIDTH_ACTIONS = {
    "domains" => %w[show],
    "demo/pages" => %w[mari carta_nautica],
    "home" => %w[index],
    "pages" => %w[flowpulse mari markpostura markpostura_old markposturastory posturacorretta],
    "nodes" => %w[show]
  }.freeze

  def full_width_layout?
    PUBLIC_FULL_WIDTH_ACTIONS.fetch(controller_path, []).include?(action_name)
  end

  def flowtree_public_node_path(node, *args)
    return nil if node.nil?
    node_path(node.resolve_target, *args)
  end

  def can_manage_nodes?(role_assignment)
    return false unless Current.user
    Current.user.superadmin_user? || (Current.user.creator_user? && Current.user.role_assignments.exists?(id: role_assignment&.id))
  end
end
