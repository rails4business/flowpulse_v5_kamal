module Brands
  module Admin
    class BaseController < ApplicationController
      BRAND_SLUG_ALIASES = {
        "corpo-e-coscienza" => "corpoecoscienza",
        "canta-che-ti-passa" => "cantachetipassa",
        "il-giardino-del-corpo" => "ilgiardinodelcorpo"
      }.freeze

      layout "brand_admin"

      before_action :require_authentication
      before_action :set_brand
      before_action :require_brand_administrator!

      helper_method :brand_owner?, :brand_support_access?, :brand_public_path, :brand_navigation_paths, :navigation_section

      private

        def set_brand
          requested_slug = request.path_parameters[:brand_slug].presence || current_domain&.resolved_node&.slug
          requested_slug = requested_slug.to_s
          canonical_slug = BRAND_SLUG_ALIASES.fetch(requested_slug, requested_slug)
          @brand = Node.includes(:domains, role_assignment: :profile).find_by!(slug: canonical_slug)
          raise ActiveRecord::RecordNotFound, "Brand non trovato" unless @brand.brand?
          if !local_request? && current_domain && current_domain.resolved_node != @brand
            raise ActiveRecord::RecordNotFound, "Il Brand non appartiene al dominio corrente"
          end
        end

        def require_brand_administrator!
          return if DashboardNavigation::Policy.new(context: dashboard_access_context).allowed?(navigation_section)

          head :forbidden
        end

        def navigation_section
          {
            "dashboard" => :dashboard, "brand_requests" => :requests,
            "node_processes" => :nodes, "node_events" => :nodes
          }.fetch(controller_name, controller_name.to_sym)
        end

        def dashboard_access_context
          context = super
          return context if context.brand || @brand.nil?
          return context unless @brand.administered_by?(Current.user)

          @dashboard_access_context = AccessContext::Resolver.new(user: Current.user, domain: @brand.domains.active.first).resolve
        end

        def brand_navigation_paths
          DashboardNavigation::Paths.new(context: dashboard_access_context,
            local: local_request? || current_domain&.resolved_node.nil?)
        end

        def brand_owner?
          @brand.owned_by?(Current.user)
        end

        def brand_support_access?
          Current.user&.superadmin_user? && !brand_owner?
        end

        def brand_public_path
          brand_navigation_paths.home
        end
    end
  end
end
