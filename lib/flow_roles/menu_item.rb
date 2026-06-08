module FlowRoles
  MenuItem = Data.define(:key, :title, :subtitle, :path, :roles, :group, :badge, :locked_label, :engine, :demo_visible, :mutating) do
    def self.build(key:, title:, subtitle:, roles:, group:, badge:, path: nil, locked_label: nil, engine: :host, demo_visible: false, mutating: false)
      new(
        key: key.to_sym,
        title: title,
        subtitle: subtitle,
        path: path,
        roles: roles.map(&:to_s),
        group: group.to_sym,
        badge: badge,
        locked_label: locked_label,
        engine: engine.to_sym,
        demo_visible: demo_visible,
        mutating: mutating
      )
    end

    def to_h
      {
        key: key,
        title: title,
        subtitle: subtitle,
        path: path,
        roles: roles,
        group: group,
        badge: badge,
        locked_label: locked_label,
        engine: engine,
        demo_visible: demo_visible,
        mutating: mutating
      }
    end
  end
end
