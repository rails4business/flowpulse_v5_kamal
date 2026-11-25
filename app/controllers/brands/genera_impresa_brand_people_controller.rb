module Brands
  class GeneraImpresaBrandPeopleController < ApplicationController
    layout "application"

    before_action :require_authentication
    before_action :set_brand
    before_action :require_manager!

    dashboard_section :genera_impresa_people

    def index
      @brand_accesses = @brand.brand_accesses
        .includes(:current_role_assignment, profile: :user)
        .order(status: :asc, joined_at: :desc, id: :desc)
    end

    def destroy
      access = @brand.brand_accesses.find(params[:id])
      BrandAccesses::Manager.new(actor: Current.user).revoke!(access, authorization_node: @brand)
      redirect_to genera_impresa_people_path, notice: "Accesso di #{access.profile.display_name} revocato."
    rescue BrandAccesses::Manager::NotAuthorized, ActiveRecord::RecordInvalid => error
      redirect_to genera_impresa_people_path, alert: error.message
    end

    private

      def set_brand
        @brand = Node.find_by!(slug: "generaimpresa")
      end

      def require_manager!
        return if Current.user.superadmin_user?
        return if dashboard_access_context.current_role_code == "gestore_generaimpresa"

        head :forbidden
      end
  end
end
