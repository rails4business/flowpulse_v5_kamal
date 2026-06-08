module Teacher
  class DashboardController < BaseController
    dashboard_section :teacher

    def show
      @role_dashboard = {
        section: :teacher,
        title: "Dashboard Teacher",
        heading: "Percorsi, corsi e lezioni",
        intro: "Area per chi costruisce e gestisce la didattica dei percorsi.",
        cards: [
          [ "Percorsi", "Struttura dei programmi e progressione didattica." ],
          [ "Corsi", "Unita pubblicabili e materiali collegati." ],
          [ "Lezioni", "Contenuti puntuali, esercizi e consegne." ]
        ]
      }
    end
  end
end
