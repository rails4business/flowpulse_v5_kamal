module Professional
  class DashboardController < BaseController
    dashboard_section :professional

    def show
      @role_dashboard = {
        section: :professional,
        title: "Dashboard Professionista",
        heading: "Servizi, abilita e disponibilita",
        intro: "Area per preparare offerta, competenze e presenza operativa del professionista.",
        cards: [
          [ "Servizi", "Cosa puo offrire il professionista." ],
          [ "Abilita", "Competenze, specializzazioni e requisiti." ],
          [ "Disponibilita", "Slot, presenza e vincoli di calendario." ]
        ]
      }
    end
  end
end
