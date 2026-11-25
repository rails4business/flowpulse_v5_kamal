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
        !superadmin? && current_role_assignment.nil?
      end

      def selection_required?
        available_role_assignments.many? && current_role_assignment.nil?
      end

      def current_role_code
        current_role_assignment&.role_operator
      end

      def access_role_code
        return "superadmin" if superadmin?

        current_role_code
      end

      def capabilities
        RoleDefinitions::Registry.find(current_role_code)&.capabilities || []
      end

      def capability?(capability)
        capabilities.include?(capability.to_sym)
      end
    end

    def initialize(user:, domain:)
      @user = user
      @domain = domain&.canonical_domain_record
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
        return if profile.blank? || brand.blank?

        profile.brand_accesses.active.find_by(brand_node: brand)
      end

      def available_assignments(brand_access)
        return [] if brand_access.blank?

        now = Time.current
        brand_access.role_assignments
          .active
          .where("starts_at IS NULL OR starts_at <= ?", now)
          .where("ends_at IS NULL OR ends_at > ?", now)
          .order(:id)
          .to_a
      end

      def resolve_current_assignment(brand_access, assignments)
        return assignments.first if assignments.one?

        selected = brand_access&.current_role_assignment
        selected if selected && assignments.include?(selected)
      end
  end
end
