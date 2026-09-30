module Brands
  module Admin
    class BaseController < ApplicationController
      layout "brand_admin"

      before_action :require_authentication
      before_action :set_brand
      before_action :require_brand_administrator!

      helper_method :brand_owner?, :brand_support_access?

      private

        def set_brand
          @brand = Node.includes(:domains, role_assignment: :profile).find_by!(slug: params[:brand_slug])
          raise ActiveRecord::RecordNotFound, "Brand non trovato" unless @brand.brand?
        end

        def require_brand_administrator!
          return if @brand.administered_by?(Current.user)

          head :forbidden
        end

        def brand_owner?
          @brand.owned_by?(Current.user)
        end

        def brand_support_access?
          Current.user&.superadmin_user? && !brand_owner?
        end
    end
  end
end
