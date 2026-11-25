class BrandAccessRolesController < ApplicationController
  before_action :require_authentication

  def update
    access = Current.user.profile.brand_accesses.active.find(params[:brand_access_id])
    unless access.brand_node == current_domain&.resolved_node
      redirect_back fallback_location: dashboard_path, alert: "Il ruolo scelto non appartiene al Brand corrente."
      return
    end

    assignment = selected_assignment(access)
    access.select_role_assignment!(assignment)

    notice = assignment ? "Ora operi come #{role_label(assignment)}." : "Ora operi come utente del Brand."
    redirect_back fallback_location: dashboard_path, notice: notice
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: dashboard_path, alert: "Ruolo non disponibile per questo Brand."
  end

  private

    def selected_assignment(access)
      assignment_id = params[:role_assignment_id].presence
      return if assignment_id.blank?

      now = Time.current
      access.role_assignments
        .active
        .where("starts_at IS NULL OR starts_at <= ?", now)
        .where("ends_at IS NULL OR ends_at > ?", now)
        .find(assignment_id)
    end

    def role_label(assignment)
      RoleDefinitions::Registry.find(assignment.role_operator)&.label || assignment.role_operator.to_s.humanize
    end
end
