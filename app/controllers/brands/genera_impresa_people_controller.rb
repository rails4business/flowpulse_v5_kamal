module Brands
  class GeneraImpresaPeopleController < ApplicationController
    layout "landing"

    before_action :require_authentication
    before_action :set_brand
    before_action :set_project

    def index
      node_ids = @project.self_and_descendants.select(:id)
      @grants = BrandAccessGrant
        .where(node_id: node_ids)
        .includes(brand_access: :profile, node: :parent)
        .order(status: :asc, granted_at: :desc)
    end

    def destroy
      grant = BrandAccessGrant.where(node_id: @project.self_and_descendants.select(:id)).find(params[:id])
      BrandAccessGrants::Manager.new(actor: Current.user, context: dashboard_access_context).revoke!(grant)
      redirect_to genera_impresa_project_people_path(@project), notice: "Accesso di #{grant.brand_access.profile.display_name} revocato dal progetto."
    rescue BrandAccessGrants::Manager::NotAuthorized, ActiveRecord::RecordInvalid => error
      redirect_to genera_impresa_project_people_path(@project), alert: error.message
    end

    private

      def set_brand
        @brand = Node.find_by!(slug: "generaimpresa")
      end

      def set_project
        @project = @brand.self_and_descendants.find(params[:project_id])
        return if RoleAssignments::AccessPolicy.allowed?(user: Current.user, action: :manage_access, node: @project, context: dashboard_access_context)

        raise ActiveRecord::RecordNotFound
      end
  end
end
