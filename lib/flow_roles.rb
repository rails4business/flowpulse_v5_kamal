module FlowRoles
  READ_ACTIONS = %i[index show read view preview].freeze
  MUTATING_ACTIONS = %i[create update destroy publish import export manage mutate].freeze
  GROUP_LABELS = {
    workspace: "Workspace",
    demo: "Demo",
    admin: "Admin"
  }.freeze
  ASIDE_CONTEXTS = {
    "traveler" => { eyebrow: "Workspace", title: "Esperienze", subtitle: "Eventi, categorie e brand" },
    "creator" => { eyebrow: "Workspace", title: "Creator World", subtitle: "Progetti, format e contenuti" },
    "teacher" => { eyebrow: "Workspace", title: "Didattica", subtitle: "Percorsi, corsi e lezioni" },
    "tutor" => { eyebrow: "Workspace", title: "Accompagnamento", subtitle: "Persone, follow-up e progressi" },
    "professional" => { eyebrow: "Workspace", title: "Professionista", subtitle: "Servizi, abilita e disponibilita" },
    "demo" => { eyebrow: "Demo", title: "Demo sandbox", subtitle: "Prototipi e viste read-only" },
    "admin" => { eyebrow: "Admin", title: "Admin", subtitle: "Strumenti operativi" },
    "superadmin" => { eyebrow: "Superadmin", title: "Superadmin", subtitle: "Governo app, domini e audit" }
  }.freeze

  module_function

  def roles
    User::SWITCHABLE_ROLES
  end

  def assignable_roles
    RoleAssignment::ROOT_ROLES
  end

  def label(role)
    User::ROLE_LABELS[role.to_s] || role.to_s.titleize
  end

  def active_role_for(user)
    user&.safe_active_role.to_s.presence || "traveler"
  end

  def can_access_role?(user, role, context = nil)
    role = role.to_s
    return false unless user
    return true if role == "traveler"
    return user.has_demo_access? if role == "demo"
    return user.superadmin_user? if role == "superadmin"
    return user.admin_user? if role == "admin"

    user.has_assigned_role?(role, context)
  end

  def dashboard_path_for(user, routes)
    return routes.root_path unless user

    case active_role_for(user)
    when "superadmin", "admin"
      routes.admin_dashboard_path
    when "creator"
      routes.creator_world_root_path
    when "teacher"
      routes.teacher_root_path
    when "tutor"
      routes.tutor_root_path
    when "professional"
      routes.professional_root_path
    when "demo"
      routes.demo_viaggiatori_path
    else
      routes.viaggiatori_path
    end
  end

  def menu_for(user, active_role:, admin: false)
    return MenuRegistry.admin_items if admin

    MenuRegistry.visible_for(
      active_role: active_role,
      superadmin: user&.superadmin_user? || false
    )
  end

  def grouped_menu_for(user, active_role:, admin: false)
    menu_for(user, active_role: active_role, admin: admin).group_by(&:group)
  end

  def group_label(group)
    GROUP_LABELS.fetch(group.to_sym, group.to_s.titleize)
  end

  def aside_context_for(active_role, admin: false)
    if admin
      role = active_role.to_s == "superadmin" ? "superadmin" : "admin"
      return ASIDE_CONTEXTS.fetch(role)
    end

    ASIDE_CONTEXTS.fetch(active_role.to_s, ASIDE_CONTEXTS.fetch("traveler"))
  end

  def can?(user, action, resource, context: nil)
    action = action.to_sym
    resource = resource.to_sym

    return READ_ACTIONS.include?(action) if resource == :public
    return false unless user

    active_role = active_role_for(user)
    return false if MUTATING_ACTIONS.include?(action) && active_role == "demo"

    case resource
    when :demo
      (active_role == "demo" || user.superadmin_user?) && user.has_demo_access? && READ_ACTIONS.include?(action)
    when :admin
      %w[admin superadmin].include?(active_role) && (user.admin_user? || user.superadmin_user?)
    when :domains, :role_map, :assigned_role_map, :superadmin
      active_role == "superadmin" && user.superadmin_user?
    else
      active_role == resource.to_s && can_access_role?(user, resource, context)
    end
  end
end

require "flow_roles/menu_item"
require "flow_roles/menu_registry"
require "flow_roles/user_roles"
require "flow_roles/controller_helpers"
