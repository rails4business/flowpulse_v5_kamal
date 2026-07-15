class HomeController < ApplicationController
  layout :home_layout

  allow_unauthenticated_access only: [:index, :progetti, :lavoro, :salute, :accademia]
  before_action :require_authentication, only: [:dashboard, :dashboard_role, :dashboard_channel]
  dashboard_section :lavoro, only: :lavoro
  dashboard_section :salute, only: [:salute, :accademia]

  def index
  end

  def dashboard
    redirect_to dashboard_home_path
  end

  def dashboard_role
    role = params[:role].to_s

    if Current.user.can_activate_role?(role)
      ra = nil
      if role == "creator"
        ra = Current.user.role_assignments.find_by(role: :creator_of_worlds)
      elsif role == "demo"
        ra = Current.user.role_assignments.find_by(role: :demo)
      elsif role == "traveler" || role == "superadmin"
        ra = nil
      else
        mapped_role = role == "admin" ? "segreteria_amministrativa" : role
        ra = Current.user.role_assignments.find_by(role: mapped_role)
      end

      Current.user.update!(active_role: role, current_role_assignment: ra)
      redirect_to dashboard_home_path, notice: "Ruolo aggiornato a #{ruolo_label(role)}"
    else
      redirect_to dashboard_home_path, alert: "Non hai i permessi per attivare questo ruolo"
    end
  end

  def dashboard_channel
    ra_id = params[:role_assignment_id].presence
    if ra_id
      ra = nil
      if Current.user.superadmin_user?
        ra = RoleAssignment.find_by(id: ra_id)
      else
        if active_dashboard_role == "creator"
          ra = Current.user.role_assignments.find_by(id: ra_id, role: :creator_of_worlds)
        elsif active_dashboard_role == "demo"
          ra = Current.user.role_assignments.find_by(id: ra_id, role: :demo)
        else
          mapped_role = active_dashboard_role == "admin" ? "segreteria_amministrativa" : active_dashboard_role
          ra = Current.user.role_assignments.find_by(id: ra_id, role: mapped_role)
        end
      end

      if ra
        Current.user.update!(current_role_assignment: ra)
        redirect_to dashboard_home_path, notice: "Canale aggiornato a #{ra.display_name}"
        return
      end
    end

    redirect_to dashboard_home_path, alert: "Canale non valido o non autorizzato"
  end

  def progetti
  end

  def lavoro
  end

  def salute
  end

  def accademia
  end

  private

    def home_layout
      %w[lavoro salute accademia].include?(action_name) ? "application" : "landing"
    end
end
