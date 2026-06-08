module Demo
  class PagesController < BaseController
    layout :demo_pages_layout
    dashboard_section :demo, only: :viaggiatori

    def mari
      # Vista dei Mari in versione demo
    end

    def viaggiatori
      # Dashboard Viaggiatori in versione demo
    end

    def carta_nautica
      # Carta Nautica in versione demo
    end

    private

      def demo_pages_layout
        action_name == "viaggiatori" ? "application" : "landing"
      end
  end
end
