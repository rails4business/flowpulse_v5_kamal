class ApplicationController < ActionController::Base
  include Authentication
  before_action :resume_session
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  DASHBOARD_ROLES = [
    [ "viaggiatori", "Viaggiatori" ],
    [ "professionisti", "Professionisti" ],
    [ "creator", "Creator" ],
    [ "superadmin", "Superadmin" ],
    [ "demo", "Demo" ]
  ].freeze

  helper_method :superadmin?, :available_dashboard_roles, :active_dashboard_role, :active_dashboard_role_label, :dashboard_home_path

  private
    def superadmin?
      Current.user&.superadmin?
    end

    def available_dashboard_roles
      DASHBOARD_ROLES
    end

    def active_dashboard_role
      return "viaggiatori" unless authenticated?
      return "viaggiatori" unless superadmin?

      session[:dashboard_role].presence_in(DASHBOARD_ROLES.map(&:first)) || "superadmin"
    end

    def active_dashboard_role_label
      available_dashboard_roles.to_h.fetch(active_dashboard_role, "Viaggiatori")
    end

    def dashboard_home_path
      return viaggiatori_path unless authenticated?
      return viaggiatori_path unless superadmin?

      active_dashboard_role == "superadmin" ? admin_dashboard_path : viaggiatori_path
    end
end
