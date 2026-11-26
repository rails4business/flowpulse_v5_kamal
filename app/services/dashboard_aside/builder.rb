module DashboardAside
  class Builder
    def initialize(context:, paths: DashboardNavigation::Paths.new(context: context))
      @context = context
      @registry = DashboardNavigation::Registry.new(context: context, paths: paths)
    end

    def applicable?
      context.brand.present? || context.user.present?
    end

    def groups
      return {} unless applicable?

      { brand: @registry.sidebar.map do |section|
        FlowRoles::MenuItem.build(key: section.key, title: section.title, subtitle: section.description,
          path: section.path, roles: [], group: :brand, badge: section.code)
      end }
    end

    def heading
      return unless applicable?

      if context.brand.nil? || context.brand.slug == "flowpulse"
        return { eyebrow: "FlowPulse", title: context.superadmin? ? "Superadmin" : "Il tuo spazio", subtitle: context.superadmin? ? "Governo della piattaforma" : "Profilo e accessi" }
      end

      if context.superadmin?
        { eyebrow: context.brand.title, title: "Assistenza superadmin", subtitle: "Gestione del Brand e controllo globale" }
      elsif context.current_role_assignment
        { eyebrow: context.brand.title, title: RoleDefinitions::Registry.fetch(context.current_role_code).label,
          subtitle: "Funzioni del tuo incarico corrente" }
      else
        { eyebrow: context.brand.title, title: context.selection_required? ? "Scegli come operare" : "Il tuo spazio",
          subtitle: "Profilo e servizi disponibili" }
      end
    end

    private

      attr_reader :context
  end
end
