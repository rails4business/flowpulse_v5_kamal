module Demo
  class ViewPagesController < ApplicationController
    allow_unauthenticated_access

    PAGES = {
      "eventi-attivita-routine" => {
        title: "Eventi, attivita e routine",
        file: "4_calendario_eventi_attività.html",
        visibility: "public"
      },
      "transazioni" => {
        title: "Transazioni",
        file: "5_transacion_cal.html",
        visibility: "public"
      },
      "percorsi-salute" => {
        title: "Percorsi salute",
        file: "1_carta_nautica.html",
        query: { mare: "salute" },
        visibility: "public"
      },
      "corsi-salute" => {
        title: "Corsi salute",
        file: "3_metro.html",
        query: { tipo: "corso", mare: "salute" },
        visibility: "public"
      },
      "evento-costi-ruoli" => {
        title: "Evento costi e ruoli",
        file: "evento_costi_ruoli.html",
        visibility: "public"
      }
    }.freeze

    def show
      load_page(params[:slug])
    end

    def eventi
      load_page("eventi-attivita-routine")
      render :show
    end

    private

      def load_page(slug)
        @page = PAGES[slug]
      raise ActionController::RoutingError, "Pagina non trovata" unless @page

        @iframe_src = view_file_path(@page)
      end

      def view_file_path(page)
        path = "/viste_html/#{page.fetch(:file)}"
        query = page[:query]

        return path if query.blank?

        "#{path}?#{query.to_query}"
      end
  end
end
