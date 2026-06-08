module CreatorWorld
  class DashboardController < BaseController
    dashboard_section :creator

    def show
      @role_dashboard = {
        section: :creator,
        title: "Dashboard Creator",
        heading: "Progetti, format e contenuti",
        intro: "Area locale per preparare CreatorWorld e il futuro engine FlowTree senza montarlo ancora.",
        cards: [
          [ "Progetti", "Mondi editoriali e iniziative da strutturare." ],
          [ "Format", "Template di percorso, contenuto o esperienza." ],
          [ "Contenuti", "Materiali che entreranno nei rami FlowTree." ]
        ]
      }
    end
  end
end
