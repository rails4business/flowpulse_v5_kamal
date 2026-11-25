module Admin
  class ProfileRoleAssignmentsController < BaseController
    before_action :require_superadmin!
    before_action :set_profile

    def create
      brand = Node.find_by!(slug: "generaimpresa")
      brand_access = @profile.brand_accesses.active.find_by(brand_node: brand)
      role_code = params[:role_code].presence_in(%w[gestore_generaimpresa imprenditore_generaimpresa])
      raise ArgumentError, "Ruolo GeneraImpresa non valido" unless role_code

      unless brand_access
        redirect_to domain_admin_path(admin_profile_path(@profile), brand_slug: "flowpulse"), alert: "Prima di assegnare il ruolo serve un accesso attivo a GeneraImpresa."
        return
      end

      RoleAssignments::Manager.new(actor: Current.user).assign_operator!(
        profile: @profile,
        brand_access: brand_access,
        node: brand,
        role_code:
      )
      role_label = RoleDefinitions::Registry.fetch(role_code).label
      redirect_to domain_admin_path(admin_profile_path(@profile), brand_slug: "flowpulse"), notice: "Ruolo #{role_label} assegnato."
    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      redirect_to domain_admin_path(admin_profile_path(@profile), brand_slug: "flowpulse"), alert: error.message
    end

    def destroy
      assignment = @profile.role_assignments.operator.find(params[:role_assignment_id])
      RoleAssignments::Manager.new(actor: Current.user).revoke!(assignment)
      redirect_to domain_admin_path(admin_profile_path(@profile), brand_slug: "flowpulse"), notice: "Ruolo revocato."
    end

    private

      def set_profile
        @profile = Profile.find(params[:profile_id])
      end
  end
end
