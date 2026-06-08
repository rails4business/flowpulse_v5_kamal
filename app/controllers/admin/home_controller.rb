module Admin
  class HomeController < BaseController
    dashboard_section :dashboard, only: :dashboard
    dashboard_section :pages, only: :elenco_pagine

    before_action :require_superadmin!, only: :elenco_pagine

    def dashboard
      # La logica della dashboard superadmin
    end

    def elenco_pagine
        @registered_pages = Demo::ViewPagesController::PAGES
      @html_files = Dir.children(Rails.root.join("public", "viste_html")).select { |file| file.ends_with?(".html") }.sort
 
    end
  end
end
