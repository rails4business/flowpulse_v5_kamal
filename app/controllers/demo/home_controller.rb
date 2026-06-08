module Demo
  class HomeController < BaseController
    layout :demo_home_layout
    dashboard_section :lavoro, only: :lavoro
    dashboard_section :salute, only: :salute

    def progetti
      # Renderizzerà app/views/demo/home/progetti.html.erb
    end

    def lavoro
      # Renderizzerà app/views/demo/home/lavoro.html.erb
    end

    def salute
      # Renderizzerà app/views/demo/home/salute.html.erb
    end

    private

      def demo_home_layout
        %w[lavoro salute].include?(action_name) ? "application" : "landing"
      end
  end
end
