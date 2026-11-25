module DashboardAside
  class Builder
    GENERA_IMPRESA_SLUG = "generaimpresa"
    FLOWPULSE_SLUG = "flowpulse"

    def initialize(context:)
      @context = context
    end

    def applicable?
      context.brand&.slug.in?([GENERA_IMPRESA_SLUG, FLOWPULSE_SLUG])
    end

    def groups
      return {} unless applicable?

      { brand: flowpulse? ? flowpulse_items : genera_impresa_items }
    end

    def heading
      return unless applicable?

      if flowpulse?
        return { eyebrow: "FlowPulse", title: context.superadmin? ? "Superadmin" : "Il tuo spazio", subtitle: context.superadmin? ? "Governo della piattaforma" : "Profilo e accessi" }
      end

      if context.superadmin?
        { eyebrow: "GeneraImpresa", title: "Assistenza superadmin", subtitle: "Gestione del Brand e controllo globale" }
      elsif current_role_code == "gestore_generaimpresa"
        { eyebrow: "GeneraImpresa", title: "Gestore", subtitle: "Richieste, persone, accessi e progetti" }
      elsif current_role_code == "imprenditore_generaimpresa"
        { eyebrow: "GeneraImpresa", title: "Imprenditore", subtitle: "Progetti e persone del tuo perimetro" }
      else
        { eyebrow: "GeneraImpresa", title: "Il tuo spazio", subtitle: "Profilo e servizi disponibili" }
      end
    end

    private

      attr_reader :context

      def genera_impresa_items
        result = [item(:genera_impresa_home, "GeneraImpresa", "Home del Brand", "/generaimpresa", "GI")]

        if context.superadmin? || capabilities.include?(:manage_requests)
          result << item(:genera_impresa_requests, "Richieste", "Accessi richiesti al Brand", "/generaimpresa/admin/requests", "REQ")
        end

        if context.superadmin? || capabilities.include?(:manage_access)
          result << item(:genera_impresa_people, "Persone", "Profile e accessi GeneraImpresa", :genera_impresa_people_path, "PER")
        end

        if context.superadmin? || capabilities.intersect?(%i[manage_projects create_children])
          result << item(:genera_impresa_projects, "Progetti", "Progetti e persone collegate", :genera_impresa_my_projects_path, "PRJ")
        end

        if context.superadmin?
          result << item(:flowpulse_admin, "Amministrazione FlowPulse", "Profile e controllo globale", :canonical_flowpulse_admin_dashboard_url, "SYS")
        elsif context.current_role_assignment.nil?
          result << item(:profile, "Profilo", "Dati personali e accessi", :profile_path, "USR")
        end

        result
      end

      def flowpulse_items
        result = [item(:flowpulse_home, "FlowPulse", "Home della piattaforma", "/", "FP")]
        if context.superadmin?
          result << item(:flowpulse_administration, "Amministrazione", "Tutte le funzioni di sistema", :admin_dashboard_path, "SYS")
          result << item(:flowpulse_profiles, "Persone e Profile", "Identità, BrandAccess e incarichi", :domain_admin_profiles_path, "PER")
        else
          result << item(:profile, "Profilo", "Dati personali e accessi", :profile_path, "USR")
        end
        result
      end

      def flowpulse?
        context.brand&.slug == FLOWPULSE_SLUG
      end

      def capabilities
        definition&.capabilities || []
      end

      def definition
        @definition ||= RoleDefinitions::Registry.find(current_role_code)
      end

      def current_role_code
        context.current_role_assignment&.role_operator
      end

      def item(key, title, subtitle, path, badge)
        FlowRoles::MenuItem.build(
          key:,
          title:,
          subtitle:,
          path:,
          roles: [],
          group: :brand,
          badge:
        )
      end
  end
end
