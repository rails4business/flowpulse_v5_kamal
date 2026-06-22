module Admin
  class HomeController < BaseController
    dashboard_section :dashboard, only: :dashboard
    dashboard_section :pages, only: :elenco_pagine

    before_action :require_superadmin!, only: [:elenco_pagine, :set_override]

    def dashboard
      @creator_worlds = RoleAssignment.creator_of_worlds.order(:id)
      @total_nodes = Node.count
      @total_contents = NodeContent.count
      @total_domains = Domain.count
      @domains = Domain.order(:hostname)
      @sample_creator_world = @creator_worlds.first
      @sample_public_node = Node.published_public.order(:id).first
    end

    def set_override
      session[:override_domain_id] = params[:domain_id].presence
      redirect_back fallback_location: admin_dashboard_path, notice: "Simulazione dominio aggiornata."
    end

    def elenco_pagine
      @registered_pages = Demo::ViewPagesController::PAGES
      @html_files = Dir.children(Rails.root.join("public", "viste_html")).select { |file| file.ends_with?(".html") }.sort
    end
  end
end
