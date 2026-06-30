module CreatorWorld
  class DashboardController < BaseController
    BASE_DOMAIN_HOSTS = %w[flowpulse.net www.flowpulse.net].freeze

    dashboard_section :creator

    def show
      @creator_domain_context = creator_domain_context
      @creator_domain_context_hosts = creator_domain_context_hosts(@creator_domain_context)
      @creator_assignments = creator_assignments
        .includes(:domains, nodes: :domains)
        .order(:id)
    end

    private

      def creator_assignments
        scope = RoleAssignment.where(role: :creator_of_worlds)
        return scope if superadmin_user?

        Current.user.role_assignments.where(role: :creator_of_worlds)
      end

      def creator_domain_context
        domain = current_domain
        return if domain.blank?
        return if BASE_DOMAIN_HOSTS.include?(domain.hostname)
        return if BASE_DOMAIN_HOSTS.include?(domain.canonical_host)

        domain
      end

      def creator_domain_context_hosts(domain)
        return [] if domain.blank?

        canonical_host = domain.canonical_host.presence || domain.hostname
        hosts = [canonical_host]
        hosts.concat(Domain.active.where(canonical_host: canonical_host).pluck(:hostname))
        hosts.uniq
      end
  end
end
