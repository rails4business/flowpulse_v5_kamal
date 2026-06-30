module Admin
  class AssignedRoleMapsController < BaseController
    dashboard_section :assigned_role_map

    before_action :require_superadmin!
    before_action :prepare_form_options, only: %i[new create]

    def show
      @role_assignments = RoleAssignment
        .includes(profile: :user, context: nil, parent: nil)
        .order(:role, :profile_id, :context_type, :context_id)
      @role_counts = RoleAssignment.group(:role).count
    end

    def new
      @role_assignment = RoleAssignment.new
    end

    def create
      identifier = params.dig(:role_assignment, :user_identifier)
      
      profile = if identifier.to_s.include?("@")
                  user = User.find_by(email_address: identifier.to_s.strip.downcase)
                  user&.profile
                else
                  Profile.find_by(username: identifier.to_s.strip.downcase)
                end

      @role_assignment = RoleAssignment.new(role_assignment_params.merge(profile_id: profile&.id))

      if profile.nil? && identifier.present?
        @role_assignment.errors.add(:profile_id, "non trovato con questa email o username")
      end

      if @role_assignment.errors.empty? && @role_assignment.save
        redirect_to admin_assigned_role_map_path, notice: "Ruolo assegnato."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

      def role_assignment_params
        params.require(:role_assignment).permit(:profile_id, :role)
      end

      def prepare_form_options
        @profiles = Profile.includes(:user).order(:username)
        @no_profile_emails = User.where.missing(:profile).pluck(:email_address)
        @assignable_roles = RoleAssignment::ROOT_ROLES
      end
  end
end
