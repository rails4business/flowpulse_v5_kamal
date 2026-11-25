module Admin
  class ProfileBrandAccessesController < BaseController
    before_action :require_superadmin!
    before_action :set_profile

    def create
      domain = Domain.active.where.not(node_id: nil).find(params.require(:domain_id))
      access = BrandAccesses::Manager.new(actor: Current.user).grant!(profile: @profile, domain: domain)
      redirect_to admin_profile_path(@profile), notice: "Accesso a #{access.brand_node.title} concesso."
    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      redirect_to admin_profile_path(@profile), alert: error.message
    end

    def destroy
      access = @profile.brand_accesses.find(params[:id])
      BrandAccesses::Manager.new(actor: Current.user).revoke!(access)
      redirect_to admin_profile_path(@profile), notice: "Accesso a #{access.brand_node.title} revocato."
    end

    private

      def set_profile
        @profile = Profile.find(params[:profile_id])
      end
  end
end
