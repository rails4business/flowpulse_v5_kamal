class BrandAccessRolesController < ApplicationController
  before_action :require_authentication

  def update
    access = Current.user.profile.brand_accesses.active.find(params[:brand_access_id])
    context = dashboard_access_context
    unless access == context.brand_access
      redirect_back fallback_location: dashboard_path, alert: "Il ruolo scelto non appartiene al Brand corrente."
      return
    end

    assignment = selected_assignment(context)
    access.select_role_assignment!(assignment)

    notice = if assignment
      "Ora operi come #{role_label(assignment)}."
    elsif context.available_role_assignments.many?
      "Scegli con quale ruolo operare nel Brand."
    else
      "Ora operi come utente del Brand."
    end
    redirect_back fallback_location: dashboard_path, notice: notice
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
    redirect_back fallback_location: dashboard_path, alert: "Ruolo non disponibile per questo Brand."
  end

  private

    def selected_assignment(context)
      assignment_id = params[:role_assignment_id].presence
      return context.available_role_assignments.first if assignment_id.blank? && context.available_role_assignments.one?
      return if assignment_id.blank?

      context.available_role_assignments.find { |assignment| assignment.id.to_s == assignment_id } ||
        raise(ActiveRecord::RecordNotFound)
    end

    def role_label(assignment)
      RoleDefinitions::Registry.find(assignment.role_operator)&.label || assignment.role_operator.to_s.humanize
    end
end
