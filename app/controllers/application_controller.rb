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

  helper_method :superadmin?, :active_dashboard_role, :active_dashboard_role_label, :dashboard_home_path, :ruolo_label

  private
    def ruolo_label(role_key)
      { "traveler" => "Viaggiatore", "demo" => "Demo", "superadmin" => "Superadmin" }[role_key.to_s] || role_key.to_s.titleize
    end
    def superadmin?
      Current.user&.superadmin == true || Current.user&.active_role == "superadmin"
    end

    def active_dashboard_role
      Current.user&.active_role || "traveler"
    end

    def active_dashboard_role_label
      labels = { "traveler" => "Viaggiatore", "demo" => "Demo", "superadmin" => "Superadmin" }
      labels[active_dashboard_role.to_s] || active_dashboard_role.to_s.titleize
    end

    def dashboard_home_path
      return root_path unless authenticated?
      
      case active_dashboard_role.to_s
      when "superadmin", "admin"
        admin_dashboard_path
      else
        viaggiatori_path
      end
    end

    def dedicated_domain_host
      ENV.fetch("DEDICATED_DOMAIN_HOST_OVERRIDE", request.host).to_s.downcase.strip
    end
end
