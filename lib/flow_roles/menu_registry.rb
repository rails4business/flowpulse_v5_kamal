module FlowRoles
  module MenuRegistry
    module_function

    def items
      @items ||= [
        MenuItem.build(
          key: :traveler,
          title: "Viaggiatore",
          subtitle: "Esperienze, categorie e brand",
          path: :viaggiatori_path,
          roles: %w[traveler demo admin superadmin],
          group: :workspace,
          badge: "EXP",
          demo_visible: true
        ),
        MenuItem.build(
          key: :demo,
          title: "Demo",
          subtitle: "Prototipi e viste sandbox",
          path: :demo_viaggiatori_path,
          roles: %w[demo superadmin],
          group: :demo,
          badge: "LAB",
          demo_visible: true
        ),
        MenuItem.build(
          key: :lavoro,
          title: "Lavoro",
          subtitle: "Creator, ruoli, attitudini, servizi",
          path: :demo_lavoro_path,
          roles: %w[demo superadmin],
          group: :demo,
          badge: "LAB",
          demo_visible: true
        ),
        MenuItem.build(
          key: :salute,
          title: "Salute",
          subtitle: "Percorsi e corsi",
          path: :demo_salute_path,
          roles: %w[demo superadmin],
          group: :demo,
          badge: "LAB",
          demo_visible: true
        ),
        MenuItem.build(
          key: :creator,
          title: "Creator",
          subtitle: "Progetti, format e contenuti",
          path: :creator_world_root_path,
          roles: %w[creator superadmin],
          group: :workspace,
          badge: "CR"
        ),
        MenuItem.build(
          key: :teacher,
          title: "Teacher",
          subtitle: "Percorsi, corsi e lezioni",
          path: :teacher_root_path,
          roles: %w[teacher superadmin],
          group: :workspace,
          badge: "EDU"
        ),
        MenuItem.build(
          key: :tutor,
          title: "Tutor",
          subtitle: "Accompagnamento e follow-up",
          path: :tutor_root_path,
          roles: %w[tutor superadmin],
          group: :workspace,
          badge: "SUP"
        ),
        MenuItem.build(
          key: :professional,
          title: "Professionista",
          subtitle: "Servizi, abilita e disponibilita",
          path: :professional_root_path,
          roles: %w[professional superadmin],
          group: :workspace,
          badge: "PRO"
        ),
        MenuItem.build(
          key: :dashboard,
          title: "Dashboard Admin",
          subtitle: "Panoramica interna",
          path: :admin_dashboard_path,
          roles: %w[admin superadmin],
          group: :admin,
          badge: "ADM",
          mutating: true
        ),
        MenuItem.build(
          key: :domains,
          title: "Domini",
          subtitle: "Gestione domini e routing",
          path: :admin_domains_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "SYS",
          mutating: true
        ),
        MenuItem.build(
          key: :resources,
          title: "Risorse",
          subtitle: "Eventi, transazioni, contatti",
          path: :admin_risorse_index_path,
          roles: %w[admin superadmin],
          group: :admin,
          badge: "ADM",
          mutating: true
        ),
        MenuItem.build(
          key: :pages,
          title: "Elenco pagine",
          subtitle: "Prototipi e viste collegate",
          path: :admin_elenco_pagine_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "SYS"
        ),
        MenuItem.build(
          key: :role_map,
          title: "Role map",
          subtitle: "Audit link per ruolo",
          path: :admin_role_map_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "SYS"
        ),
        MenuItem.build(
          key: :assigned_role_map,
          title: "Assigned roles",
          subtitle: "Utenti e ruoli assegnati",
          path: :admin_assigned_role_map_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "SYS"
        ),
        MenuItem.build(
          key: :weekplan,
          title: "Weekplan",
          subtitle: "Planner settimanale HTML",
          path: "/viste_html/6_weekplan.html",
          roles: %w[admin superadmin],
          group: :admin,
          badge: "ADM"
        )
      ].freeze
    end

    def roles
      User::SWITCHABLE_ROLES
    end

    def items_for_role(role)
      role = role.to_s
      items.select { |item| item.roles.include?(role) }
    end

    def admin_items
      admin_keys = %i[dashboard domains resources pages role_map assigned_role_map weekplan]
      items.select { |item| admin_keys.include?(item.key) }
    end

    def visible_for(active_role:, superadmin: false)
      items_for_role(active_role)
    end
  end
end
