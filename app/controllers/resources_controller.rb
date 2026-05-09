class ResourcesController < ApplicationController
  allow_unauthenticated_access

  TABS = [
    { key: "eventi", label: "Eventi" },
    { key: "transazioni", label: "Transazioni" },
    { key: "contatti", label: "Contatti" },
    { key: "attenzione", label: "Attenzione" },
    { key: "luoghi", label: "Luoghi" },
    { key: "abilita", label: "Abilita" },
    { key: "energia", label: "Energia" }
  ].freeze

  def index
    @active_tab = normalized_tab(params[:tab])
    @tabs = TABS
    @resources = resources_for(@active_tab)
  end

  def show
    @tabs = TABS
    @resource = find_resource(params[:id])

    unless @resource
      redirect_to resources_path, alert: "Risorsa non trovata"
      return
    end

    render :detail
  end

  private

    def normalized_tab(tab)
      TABS.find { |item| item[:key] == tab }&.fetch(:key) || "eventi"
    end

    def resources_for(tab)
      case tab
      when "eventi"
        [
          { id: 1, tab: "eventi", type: "Evento", title: "Postura in Vetta", description: "Esperienza guidata con professionisti, luogo e ruoli collegati.", icon: "Calendario" },
          { id: 2, tab: "eventi", type: "Evento", title: "Inside Adventure Lab", description: "Format esperienziale con brand, creator e partecipanti.", icon: "Rotta" },
          { id: 3, tab: "eventi", type: "Evento", title: "Sessione Sapienza Visione", description: "Evento piu raccolto con obiettivo formativo.", icon: "Cerchio" }
        ]
      when "transazioni"
        [
          { id: 10, tab: "transazioni", type: "Transazione", title: "Riparto evento Postura in Vetta", description: "Quote tra professionista, brand, segreteria e segnalatore.", icon: "Scambio" },
          { id: 11, tab: "transazioni", type: "Transazione", title: "Saldo experience luogo", description: "Valore riconosciuto al responsabile del luogo.", icon: "Valore" },
          { id: 12, tab: "transazioni", type: "Transazione", title: "Liquidazione segreteria", description: "Costo organizzativo e gestione agenda.", icon: "Nodo" }
        ]
      when "contatti"
        [
          { id: 20, tab: "contatti", type: "Contatto", title: "Marco Rossi", description: "Professionista postura e mobilita articolare.", icon: "Persona" },
          { id: 21, tab: "contatti", type: "Contatto", title: "Elena Verdi", description: "Segreteria organizzativa e follow-up.", icon: "Segreteria" },
          { id: 22, tab: "contatti", type: "Contatto", title: "Inside Adventure", description: "Brand partner con experiences sul territorio.", icon: "Brand" }
        ]
      when "attenzione"
        [
          { id: 30, tab: "attenzione", type: "Attenzione", title: "Confermare i ruoli del luogo", description: "Manca l'assegnazione del professionista responsabile del luogo.", icon: "Focus" },
          { id: 31, tab: "attenzione", type: "Attenzione", title: "Riparto brand non validato", description: "La quota economica del brand e ancora da definire.", icon: "Allerta" },
          { id: 32, tab: "attenzione", type: "Attenzione", title: "Follow-up partecipanti", description: "Da decidere il flusso di segnalazione e conferma.", icon: "Cura" }
        ]
      when "luoghi"
        [
          { id: 40, tab: "luoghi", type: "Luogo", title: "Rifugio A", description: "Luogo con professionista responsabile e attivita outdoor.", icon: "Luogo" },
          { id: 41, tab: "luoghi", type: "Luogo", title: "Studio Centro", description: "Spazio per corsi, incontri singoli e piccoli gruppi.", icon: "Spazio" },
          { id: 42, tab: "luoghi", type: "Luogo", title: "Area Benessere Nord", description: "Polo per eventi salute e attivazioni di brand.", icon: "Mappa" }
        ]
      when "abilita"
        [
          { id: 50, tab: "abilita", type: "Abilita", title: "Valutazione mobilita articolare", description: "Servizio tecnico erogabile da professionisti del network.", icon: "Abilita" },
          { id: 51, tab: "abilita", type: "Abilita", title: "Togliere le tensioni", description: "Prestazione o micropercorso agganciabile a un evento.", icon: "Servizio" },
          { id: 52, tab: "abilita", type: "Abilita", title: "Riattivare i recettori", description: "Skill / servizio ad alto valore formativo.", icon: "Metodo" }
        ]
      when "energia"
        [
          { id: 60, tab: "energia", type: "Energia", title: "Capacita del team questa settimana", description: "Energia disponibile per eventi, contatti e transazioni.", icon: "Energia" },
          { id: 61, tab: "energia", type: "Energia", title: "Attenzione operativa", description: "Quanto focus reale c'e per far girare i progetti.", icon: "Flusso" },
          { id: 62, tab: "energia", type: "Energia", title: "Tempo dei professionisti", description: "Disponibilita da allocare tra brand, luoghi e corsi.", icon: "Tempo" }
        ]
      else
        []
      end
    end

    def find_resource(id)
      TABS.flat_map { |tab| resources_for(tab[:key]) }.find { |resource| resource[:id].to_s == id.to_s }
    end
end
