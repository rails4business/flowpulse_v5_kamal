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
          roles: %w[traveler admin superadmin],
          group: :workspace,
          badge: "EXP",
          demo_visible: true
        ),
        MenuItem.build(
          key: :ideatore,
          title: "Ideatore",
          subtitle: "Brand, progetti e root node",
          path: :creator_world_root_path,
          roles: %w[ideatore superadmin],
          group: :workspace,
          badge: "CR"
        ),
        MenuItem.build(
          key: :creator_roles,
          title: "Ruoli",
          subtitle: "Gestione ruoli dipendenti",
          path: :creator_world_role_assignments_path,
          roles: %w[ideatore superadmin],
          group: :workspace,
          badge: "ROL"
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
          key: :notes,
          title: "Appunti",
          subtitle: "Documentazione e piani Markdown",
          path: :admin_notes_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "MD"
        ),
        MenuItem.build(
          key: :didactic_path,
          title: "Percorso didattico",
          subtitle: "Schema, regole e fonti YAML",
          path: :admin_percorso_insegnanti_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "EDU"
        ),
        MenuItem.build(
          key: :content_taxonomy,
          title: "Gestione contenuti",
          subtitle: "Catalogo, tassonomia e filtri",
          path: :admin_content_taxonomy_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "CNT"
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
          key: :password_reset_requests,
          title: "Reset password",
          subtitle: "Richieste e link temporanei",
          path: :admin_password_reset_requests_path,
          roles: %w[superadmin],
          group: :admin,
          badge: "SEC",
          mutating: true
        ),
        MenuItem.build(key: :data_commitment_imports, title: "Importa impegni", subtitle: "Esporta, anteprima e conferma", path: :admin_data_commitment_imports_path, roles: %w[superadmin], group: :admin, badge: "SYNC", mutating: true),
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
      admin_keys = %i[dashboard resources pages notes didactic_path content_taxonomy role_map assigned_role_map password_reset_requests data_commitment_imports weekplan]
      items.select { |item| admin_keys.include?(item.key) }
    end

    def visible_for(active_role:, superadmin: false)
      items_for_role(active_role)
    end
  end
end
