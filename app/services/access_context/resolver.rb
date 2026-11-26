module AccessContext
  class Resolver
    Result = Data.define(
      :user,
      :profile,
      :domain,
      :brand,
      :brand_access,
      :available_role_assignments,
      :current_role_assignment,
      :superadmin
    ) do
      def superadmin?
        superadmin
      end

      def user?
        !superadmin? && brand_access.present? && available_role_assignments.empty?
      end

      def guest?
        !superadmin? && brand_access.nil?
      end

      def selection_required?
        !superadmin? && available_role_assignments.many? && current_role_assignment.nil?
      end

      def current_role_code
        RoleDefinitions::Registry.canonical_code(current_role_assignment&.role_operator)
      end

      def access_role_code
        return "superadmin" if superadmin?

        current_role_code
      end

      def capabilities
        return [] unless RoleDefinitions::Registry.compatible_with_brand?(current_role_code, brand)

        RoleDefinitions::Registry.fetch(current_role_code).capabilities
      end

      def capability?(capability)
        capabilities.include?(capability.to_sym)
      end
    end

    def initialize(user:, domain:)
      @user = user
      @domain = domain&.canonical_domain_record if domain&.active?
    end

    def resolve
      profile = user&.profile
      brand = domain&.resolved_node
      brand_access = find_brand_access(profile, brand)
      assignments = available_assignments(brand_access)

      Result.new(
        user:,
        profile:,
        domain:,
        brand:,
        brand_access:,
        available_role_assignments: assignments,
        current_role_assignment: resolve_current_assignment(brand_access, assignments),
        superadmin: user&.superadmin_user? || false
      )
    end

    private

      attr_reader :user, :domain

      def find_brand_access(profile, brand)
        return if profile.blank? || brand.blank? || !domain&.active? || !user.active_registration?

        profile.brand_accesses.active.find_by(brand_node: brand)
      end

      def available_assignments(brand_access)
        return [] if brand_access.blank?

        brand_access.role_assignments
          .currently_effective
          .where(profile_id: brand_access.profile_id, role: :operator)
          .includes(:context)
          .order(:id)
          .select { |assignment| assignment.effective_for_access?(brand_access) }
      end

      def resolve_current_assignment(brand_access, assignments)
        return assignments.first if assignments.one?

        assignments.find { |assignment| assignment.id == brand_access&.current_role_assignment_id }
      end
  end
end
