module Admin
  class PasswordResetRequestsController < BaseController
    dashboard_section :password_reset_requests
    before_action :require_superadmin!

    def index
      @password_reset_requests = PasswordResetRequest.includes(:user).recent_first
      @reset_links = @password_reset_requests.select(&:pending?).to_h do |reset_request|
        [reset_request.id, edit_password_url(reset_request.user.password_reset_token, host: request.host, protocol: request.protocol)]
      end
    end

    def complete
      password_reset_request = PasswordResetRequest.find(params[:id])
      password_reset_request.update!(fulfilled_at: Time.current)
      redirect_to admin_password_reset_requests_path, notice: "Richiesta archiviata."
    end
  end
end
