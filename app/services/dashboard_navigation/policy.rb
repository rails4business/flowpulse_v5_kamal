module DashboardNavigation
  class Policy
    TECHNICAL_SECTIONS = %i[nodes schema development contents data_commitments privacy].freeze

    def initialize(context:)
      @context = context
    end

    def allowed?(section)
      case section.to_sym
      when :platform
        context.superadmin?
      when :dashboard
        platform? ? allowed?(:platform) : brand_dashboard?
      when *TECHNICAL_SECTIONS
        !platform? && full_brand_access?
      when :requests
        return false if platform? || brand.nil?
        return context.superadmin? || (context.current_role_code == "gestore_generaimpresa" && permits?(:manage_requests, brand)) if genera_impresa?

        full_brand_access? || permits?(:manage_requests, brand)
      when :brand_people
        genera_impresa? && (context.superadmin? || manager?)
      when :projects
        genera_impresa? && (full_brand_access? || permits?(:manage_projects, assignment&.context) ||
          permits?(:create_node, assignment&.context))
      else
        false
      end
    end

    def platform?
      brand.nil? || brand.slug == "flowpulse"
    end

    def full_brand_access?
      context.superadmin? || (brand.present? && (brand.owned_by?(context.user) || legacy_brand_administrator?))
    end

    private

      attr_reader :context

      # Gli incarichi strutturali vengono migrati nel passo 6, senza estendere i nuovi ruoli.
      def legacy_brand_administrator?
        profile = context.user&.profile
        profile.present? && RoleAssignment.where(profile: profile, context: brand, role: %i[admin responsabile]).exists?
      end

      def brand
        context.brand
      end

      def assignment
        context.current_role_assignment
      end

      def genera_impresa?
        brand&.slug == "generaimpresa"
      end

      def manager?
        context.current_role_code == "gestore_generaimpresa" && permits?(:manage_access, brand)
      end

      def brand_dashboard?
        brand.present? && (context.selection_required? || full_brand_access? || allowed?(:requests) || allowed?(:brand_people) || allowed?(:projects))
      end

      def permits?(action, node)
        RoleAssignments::AccessPolicy.allowed?(user: context.user, action: action, node: node, context: context)
      end
  end
end
