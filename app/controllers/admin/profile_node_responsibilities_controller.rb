module Admin
  class ProfileNodeResponsibilitiesController < BaseController
    before_action :require_superadmin!
    before_action :set_profile

    def create
      node = Node.find(params.require(:node_id))
      role_code = params.require(:role_code)
      NodeResponsibilities::Manager.new(actor: Current.user).assign!(node: node, profile: @profile, role_code: role_code)
      redirect_to domain_admin_path(admin_profile_nodes_path(@profile), brand_slug: "flowpulse"), notice: "#{node.title} affidato a #{@profile.display_name}."
    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      redirect_to domain_admin_path(admin_profile_nodes_path(@profile), brand_slug: "flowpulse"), alert: error.message
    end

    def destroy
      node = @profile.responsible_nodes.find(params[:id])
      NodeResponsibilities::Manager.new(actor: Current.user).remove!(node: node, profile: @profile)
      redirect_to domain_admin_path(admin_profile_nodes_path(@profile), brand_slug: "flowpulse"), notice: "Responsabilità di #{node.title} rimossa."
    end

    private

      def set_profile
        @profile = Profile.find(params[:profile_id])
      end
  end
end
