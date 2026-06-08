class ApplicationController < ActionController::Base
  include Authentication
  include CurrentDomain
  include FlowRoles::ControllerHelpers
  helper_method :dashboard_current_section
  before_action :resume_session
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  DASHBOARD_ROLES = User::SWITCHABLE_ROLES.map { |role| [ role, User::ROLE_LABELS.fetch(role, role.titleize) ] }.freeze

  def self.dashboard_section(section, **options)
    before_action(**options) do
      @dashboard_current_section = section.to_sym
    end
  end

  private

    def dashboard_current_section
      @dashboard_current_section || :dashboard
    end
end
