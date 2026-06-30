module CreatorWorld
  class RoleAssignmentsController < BaseController
    dashboard_section :creator_roles

    before_action :ensure_active_channel
    before_action :prepare_form_options, only: %i[new create]

    def index
      @role_assignments = RoleAssignment
        .where(parent_id: @active_channel.id)
        .includes(profile: :user)
        .order(:role, :profile_id)
    end

    def new
      @role_assignment = RoleAssignment.new(parent: @active_channel)
    end

    def create
      username = params.dig(:role_assignment, :username)
      profile = Profile.find_by(username: username)

      @role_assignment = RoleAssignment.new(role_assignment_params.merge(profile_id: profile&.id, parent_id: @active_channel.id))

      if profile.nil? && username.present?
        @role_assignment.errors.add(:profile_id, "profilo non trovato con questo username")
      end

      if RoleAssignment::ROOT_ROLES.include?(@role_assignment.role.to_s)
        @role_assignment.errors.add(:role, "non può essere assegnato da un creator")
      end

      if @role_assignment.errors.empty? && @role_assignment.save
        redirect_to creator_world_role_assignments_path, notice: "Ruolo assegnato con successo."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @role_assignment = RoleAssignment.find_by!(id: params[:id], parent_id: @active_channel.id)
      @role_assignment.destroy!
      redirect_to creator_world_role_assignments_path, notice: "Assegnazione revocata."
    end

    private

      def role_assignment_params
        params.require(:role_assignment).permit(:role)
      end

      def ensure_active_channel
        @active_channel = Current.user.current_role_assignment
        if @active_channel.nil? || !@active_channel.creator_of_worlds?
          fallback_channel = if superadmin_user?
                               RoleAssignment.creator_of_worlds.first
                             else
                               Current.user.role_assignments.creator_of_worlds.first
                             end

          if fallback_channel
            Current.user.update!(current_role_assignment: fallback_channel)
            @active_channel = fallback_channel
          else
            redirect_to creator_world_root_path, alert: "Nessun canale attivo disponibile. Contatta l'amministratore."
          end
        end
      end

      def prepare_form_options
        @profiles = Profile.order(:username)
        @assignable_roles = RoleAssignment.roles.keys - RoleAssignment::ROOT_ROLES
      end
  end
end
