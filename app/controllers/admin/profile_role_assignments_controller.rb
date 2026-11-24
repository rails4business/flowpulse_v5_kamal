module Admin
  class ProfileRoleAssignmentsController < BaseController
    before_action :require_superadmin!
    before_action :set_profile

    def create
      brand = Node.find_by!(slug: "generaimpresa")
      assignment = @profile.role_assignments.new(
        role: :operator,
        role_operator: "creator_generaimpresa",
        context: brand,
        parent: brand.role_assignment
      )

      if assignment.save
        redirect_to admin_profile_path(@profile), notice: "Ruolo Creatore GeneraImpresa assegnato."
      else
        redirect_to admin_profile_path(@profile), alert: assignment.errors.full_messages.to_sentence
      end
    end

    def destroy
      assignment = @profile.role_assignments.operator.find(params[:role_assignment_id])
      assignment.destroy!
      redirect_to admin_profile_path(@profile), notice: "Ruolo revocato."
    end

    private

      def set_profile
        @profile = Profile.find(params[:profile_id])
      end
  end
end
