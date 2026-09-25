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

      assignment_attributes = role_assignment_params.merge(profile_id: profile&.id)
      if assignment_attributes[:role] == "operator"
        brand = @operator_brands.find { |node| node.id == params.dig(:role_assignment, :brand_id).to_i }
        if brand.present?
          assignment_attributes.merge!(context: brand, parent: brand.role_assignment)
        else
          assignment_attributes[:context] = nil
        end
      else
        assignment_attributes[:role_operator] = nil
      end
      @role_assignment = RoleAssignment.new(assignment_attributes)

      if profile.nil? && identifier.present?
        @role_assignment.errors.add(:profile_id, "non trovato con questa email o username")
      end

      if @role_assignment.operator? && @role_assignment.context.blank?
        @role_assignment.errors.add(:context, "seleziona un Brand")
      elsif !RoleAssignment::ROOT_ROLES.include?(@role_assignment.role) && !@role_assignment.operator?
        @role_assignment.errors.add(:role, "non è assegnabile da questa pagina")
      end

      if @role_assignment.errors.empty? && @role_assignment.save
        redirect_to admin_assigned_role_map_path, notice: "Ruolo assegnato."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

      def role_assignment_params
        params.require(:role_assignment).permit(:profile_id, :role, :role_operator)
      end

      def prepare_form_options
        @profiles = Profile.includes(:user).order(:username)
        @no_profile_emails = User.where.missing(:profile).pluck(:email_address)
        @operator_brands = Node.joins(:domains).distinct.includes(:role_assignment).order(:title, :id)
        @assignable_roles = RoleAssignment::ROOT_ROLES + [ "operator" ]
      end
  end
end
