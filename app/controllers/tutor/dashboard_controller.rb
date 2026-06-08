module Tutor
  class DashboardController < BaseController
    dashboard_section :tutor

    def show
      @role_dashboard = {
        section: :tutor,
        title: "Dashboard Tutor",
        heading: "Accompagnamento e follow-up",
        intro: "Area per supportare persone, progressi e passaggi operativi.",
        cards: [
          [ "Persone", "Utenti seguiti e priorita di attenzione." ],
          [ "Follow-up", "Promemoria, note e prossime azioni." ],
          [ "Progressi", "Stato dei percorsi e segnali da monitorare." ]
        ]
      }
    end
  end
end
