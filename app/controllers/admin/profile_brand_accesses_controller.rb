module Admin
  class ProfileBrandAccessesController < BaseController
    before_action :require_superadmin!
    before_action :set_profile

    def index
      @brand_accesses = @profile.brand_accesses
        .includes(:brand_node, :source_domain)
        .order(:status, :joined_at, :id)
      @available_domains = Domain.active.where.not(node_id: nil).includes(:node).order(:hostname)
    end

    def show
      @brand_access = @profile.brand_accesses
        .includes(:source_domain, :brand_node, grants: %i[node brand_request granted_by_profile])
        .find(params[:id])
      @role_assignments = @profile.role_assignments.where(brand_access: @brand_access)
        .includes(:context, :assigned_by_profile)
        .order(:role_operator, :created_at)
    end

    def create
      domain = Domain.active.where.not(node_id: nil).find(params.require(:domain_id))
      access = BrandAccesses::Manager.new(actor: Current.user).grant!(profile: @profile, domain: domain)
      redirect_to admin_profile_brand_accesses_path(@profile), notice: "Accesso a #{access.brand_node.title} concesso."
    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      redirect_to admin_profile_brand_accesses_path(@profile), alert: error.message
    end

    def destroy
      access = @profile.brand_accesses.find(params[:id])
      BrandAccesses::Manager.new(actor: Current.user).revoke!(access)
      redirect_to admin_profile_brand_accesses_path(@profile), notice: "Accesso a #{access.brand_node.title} revocato."
    end

    private

      def set_profile
        @profile = Profile.find(params[:profile_id])
      end
  end
end
