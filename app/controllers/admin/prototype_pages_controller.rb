module Admin
  class PrototypePagesController < BaseController
    before_action :require_superadmin!

    PROTOTYPES_ROOT = Rails.root.join("docs/private_prototypes").freeze

    def show
      root = PROTOTYPES_ROOT.realpath
      file = root.join(params[:path].to_s).cleanpath

      return head :not_found unless file.file? && file.to_s.start_with?("#{root}/")

      send_file file, disposition: "inline", type: Rack::Mime.mime_type(file.extname, "text/plain")
    end
  end
end
