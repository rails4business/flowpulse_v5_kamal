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

      helper_method :brand_owner?, :brand_support_access?

      private

        def set_brand
          requested_slug = params[:brand_slug].to_s
          canonical_slug = BRAND_SLUG_ALIASES.fetch(requested_slug, requested_slug)
          @brand = Node.includes(:domains, role_assignment: :profile).find_by!(slug: canonical_slug)
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
