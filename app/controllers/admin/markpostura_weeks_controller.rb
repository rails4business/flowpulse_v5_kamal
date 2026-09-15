module Admin
  class MarkposturaWeeksController < BaseController
    before_action :require_superadmin!

    def show
      source = MarkposturaHome.week_source(params[:week])
      raise ActionController::RoutingError, "Settimana non trovata" unless source

      @week_key = params[:week]
      @week_path = source.fetch(:path)
      @week_content = source.fetch(:content)
    end
  end
end
