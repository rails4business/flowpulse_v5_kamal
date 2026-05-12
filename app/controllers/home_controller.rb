class HomeController < ApplicationController
  allow_unauthenticated_access only: [:index, :progetti, :lavoro, :salute]
  before_action :require_authentication, only: [:dashboard, :dashboard_role]

  def index
  end

  def dashboard
    redirect_to dashboard_home_path
  end

  def dashboard_role
    role = params[:role].to_s
    
    if superadmin? || Current.user.can_activate_role?(role)
      Current.user.update!(active_role: role)
      redirect_to dashboard_home_path, notice: "Ruolo aggiornato a #{role.titleize}"
    else
      redirect_to dashboard_home_path, alert: "Non hai i permessi per attivare questo ruolo"
    end
  end

  def progetti
  end

  def lavoro
  end

  def salute
  end
end
