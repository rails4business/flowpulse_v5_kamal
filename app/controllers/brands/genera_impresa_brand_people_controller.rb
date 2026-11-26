module Brands
  class GeneraImpresaBrandPeopleController < ApplicationController
    layout "application"

    before_action :require_authentication
    before_action :set_brand
    before_action :require_manager!

    dashboard_section :genera_impresa_people

    def index
      @brand_accesses = @brand.brand_accesses
        .includes(:brand_credential, :current_role_assignment, profile: :user)
        .order(status: :asc, joined_at: :desc, id: :desc)
    end

    def resend_verification
      access = @brand.brand_accesses.find(params[:id])
      result = BrandCredentials::VerificationIssuer.new.issue!(access)
      flash[:verification_url] = result.confirmation_url
      flash[:verification_email] = access.brand_credential.email_address
      redirect_to genera_impresa_people_path,
        notice: "Nuovo link di attivazione generato. Copialo oppure apri l’email precompilata."
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      redirect_to genera_impresa_people_path, alert: error.message
    end

    def destroy
      access = @brand.brand_accesses.find(params[:id])
      BrandAccesses::Manager.new(actor: Current.user, context: dashboard_access_context).revoke!(access, authorization_node: @brand)
      redirect_to genera_impresa_people_path, notice: "Accesso di #{access.profile.display_name} revocato."
    rescue BrandAccesses::Manager::NotAuthorized, ActiveRecord::RecordInvalid => error
      redirect_to genera_impresa_people_path, alert: error.message
    end

    private

      def set_brand
        @brand = Node.find_by!(slug: "generaimpresa")
      end

      def require_manager!
        return if DashboardNavigation::Policy.new(context: dashboard_access_context).allowed?(:brand_people)

        head :forbidden
      end
  end
end
