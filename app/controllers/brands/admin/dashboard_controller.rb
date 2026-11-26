module Brands
  module Admin
    class DashboardController < BaseController
      def index
        @sections = DashboardNavigation::Registry.new(context: dashboard_access_context, paths: brand_navigation_paths).sections
      end
    end
  end
end
