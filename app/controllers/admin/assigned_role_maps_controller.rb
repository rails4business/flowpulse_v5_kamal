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
      @selected_domain_id = params.dig(:role_assignment, :domain_id).presence
      selected_domain = Domain.active.find_by(id: @selected_domain_id)
      
      profile = if identifier.to_s.include?("@")
                  user = User.find_by(email_address: identifier.to_s.strip.downcase)
                  user&.profile
                else
                  Profile.find_by(username: identifier.to_s.strip.downcase)
                end

      assignment_attributes = role_assignment_params.merge(profile_id: profile&.id)
      if selected_domain.present?
        assignment_attributes.merge!(context: selected_domain, parent: selected_domain.role_assignment)
      end
      @role_assignment = RoleAssignment.new(assignment_attributes)

      if profile.nil? && identifier.present?
        @role_assignment.errors.add(:profile_id, "non trovato con questa email o username")
      end

      if @selected_domain_id.present? && selected_domain.blank?
        @role_assignment.errors.add(:context, "dominio non valido")
      elsif selected_domain.present?
        unless Array(selected_domain.operational_roles).include?(@role_assignment.role)
          @role_assignment.errors.add(:role, "non è previsto per #{selected_domain.display_hostname}")
        end
        if selected_domain.role_assignment.blank?
          @role_assignment.errors.add(:parent, "manca: assegna prima il Creator world al dominio")
        end
      elsif !RoleAssignment::ROOT_ROLES.include?(@role_assignment.role)
        @role_assignment.errors.add(:context, "seleziona un dominio per assegnare un ruolo operativo")
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
        @operational_domains = Domain.active.select { |domain| Array(domain.operational_roles).any? }.sort_by(&:hostname)
        @assignable_roles = (RoleAssignment::ROOT_ROLES + @operational_domains.flat_map { |domain| Array(domain.operational_roles) }).uniq
      end
  end
end
