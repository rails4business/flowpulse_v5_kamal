module Admin
  class BaseController < ApplicationController
    before_action :use_platform_host
    before_action :require_admin!

    private

    def use_platform_host
      return if local_request? || current_domain&.resolved_node.nil? || current_domain.resolved_node.slug == "flowpulse"

      if request.get? || request.head?
        redirect_to "https://flowpulse.net#{request.fullpath}", allow_other_host: true
      else
        head :not_found
      end
    end

    def dashboard_access_context
      @dashboard_access_context ||= AccessContext::Resolver.new(
        user: Current.user,
        domain: flowpulse_admin_domain || current_domain
      ).resolve
    end

    def flowpulse_admin_domain
      @flowpulse_admin_domain ||= Domain.active
        .joins(:node)
        .where(nodes: { slug: "flowpulse" })
        .order(primary: :desc, id: :asc)
        .first
        &.canonical_domain_record
    end

    def require_admin!
      return if Current.user&.superadmin_user?

      require_permission!(:admin)
    end

    def require_superadmin!
      return if Current.user&.superadmin_user?

      redirect_to dashboard_home_path, alert: "Accesso riservato al superadmin."
    end
  end
end
