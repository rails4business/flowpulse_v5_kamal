class HomeController < ApplicationController
  allow_unauthenticated_access
  before_action :require_authentication, only: [:dashboard, :dashboard_role]

  def index
  end

  def dashboard
    redirect_to dashboard_home_path
  end


  def dashboard_role
    if superadmin? && params[:role].presence_in(available_dashboard_roles.map(&:first))
      session[:dashboard_role] = params[:role]
    end

    redirect_to dashboard_home_path
  end

  def progetti
  end

  def lavoro
  end

  def salute
  end

end
