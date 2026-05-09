class PublicEventsController < ApplicationController
  skip_before_action :require_authentication, only: [:index, :show]

  TABS = {
    "eventi" => { label: "Eventi", internal: false },
    "avventure" => { label: "Avventure", internal: false },
    "servizi" => { label: "Servizi", internal: false },
    "corsi" => { label: "Corsi", internal: false }
  }.freeze

  def index
    @tabs = visible_tabs
    @active_tab = normalized_tab(params[:tab])
    @items = items_for(@active_tab)
  end

  def show
    @event = mock_public_event(params[:id])
    redirect_to eventi_path unless @event
  end

  private

  def visible_tabs
    TABS
  end

  def normalized_tab(tab)
    TABS.key?(tab) ? tab : "eventi"
  end

  def items_for(tab)
    case tab
    when "avventure"
      mock_public_adventures
    when "servizi"
      mock_public_services
    when "corsi"
      mock_public_courses
    else
      mock_public_experiences
    end
  end

  def mock_public_experiences
    [
      {
        id: 1,
        category: "experience",
        title: "Postura in Vetta",
        description: "Esperienza pubblica tra cammino, postura e riattivazione del corpo in gruppo.",
        details: "Un format Flowpulse che mette insieme cammino, postura, educazione e relazione con il territorio.",
        icon: "Esperienza",
        month: "MAG",
        day: "15",
        weekday: "Giovedi",
        date: "15 Maggio 2026",
        time: "08:30 - 13:30",
        brand: "PosturaCorretta",
        organizer: "Professionista singolo + gruppo",
        location: "Rifugio A, Monte Bar",
        event_kind: "Evento",
        schedule_label: "1 giornata",
        sessions: [
          { label: "Giornata 1", date: "15 Maggio 2026", time: "08:30 - 13:30", location: "Rifugio A, Monte Bar" }
        ],
        format: "PosturaCorretta in vetta",
        participants: "18 partecipanti",
        duration: "5 ore"
      },
      {
        id: 2,
        category: "experience",
        title: "Inside Adventure Lab",
        description: "Esperienza aperta per esplorare brand, corpo e avventura educativa sul territorio.",
        details: "Una giornata pubblica dove esperienza, creator e professionisti lavorano nello stesso formato.",
        icon: "Rotta",
        month: "MAG",
        day: "20",
        weekday: "Martedi",
        date: "20 Maggio 2026",
        time: "10:00 - 17:30",
        brand: "Inside Adventure",
        organizer: "Organizzazione di gruppo",
        location: "Lago di Como",
        event_kind: "Seminario",
        schedule_label: "3 giornate",
        sessions: [
          { label: "Giornata 1", date: "20 Maggio 2026", time: "10:00 - 17:30", location: "Lago di Como" },
          { label: "Giornata 2", date: "21 Maggio 2026", time: "10:00 - 17:30", location: "Lago di Como" },
          { label: "Giornata 3", date: "22 Maggio 2026", time: "10:00 - 16:00", location: "Lago di Como" }
        ],
        format: "Inside Adventure in spiaggetta",
        participants: "24 partecipanti",
        duration: "7 ore e 30"
      },
      {
        id: 3,
        category: "experience",
        title: "Sapienza Visione dal vivo",
        description: "Esperienza piu raccolta con parte formativa, confronto e osservazione guidata.",
        details: "Una tappa pubblica pensata per raccontare principi, strumenti e applicazioni concrete.",
        icon: "Visione",
        month: "GIU",
        day: "01",
        weekday: "Lunedi",
        date: "1 Giugno 2026",
        time: "18:45 - 21:00",
        brand: "Sapienza Visione",
        organizer: "Professionista singolo",
        location: "Milano, studio centrale",
        event_kind: "Seminario",
        schedule_label: "3 serate",
        sessions: [
          { label: "Serata 1", date: "1 Giugno 2026", time: "18:45 - 21:00", location: "Milano, studio centrale" },
          { label: "Serata 2", date: "8 Giugno 2026", time: "18:45 - 21:00", location: "Milano, studio centrale" },
          { label: "Serata 3", date: "15 Giugno 2026", time: "18:45 - 21:00", location: "Milano, studio centrale" }
        ],
        format: "Sapienza Visione in sala",
        participants: "12 partecipanti",
        duration: "2 ore e 15"
      }
    ]
  end

  def mock_public_event(id)
    (mock_public_experiences + mock_public_adventures + mock_public_services + mock_public_courses).find { |e| e[:id].to_s == id.to_s }
  end

  def mock_public_adventures
    [
      {
        id: 101,
        category: "adventure",
        title: "Alba fuori rotta",
        description: "Avventura nata al volo, privata prima della pubblicazione finale.",
        details: "Esperienza improvvisata, documentata e poi pubblicabile come storia o format.",
        icon: "Bussola",
        month: "MAG",
        day: "22",
        weekday: "Venerdi",
        date: "22 Maggio 2026",
        time: "05:40 - 09:15",
        brand: "Inside Adventure",
        organizer: "Piccolo gruppo",
        location: "Lago Maggiore",
        format: "Adventure all'alba",
        participants: "8 partecipanti",
        duration: "3 ore e 35"
      },
      {
        id: 102,
        category: "adventure",
        title: "Notte di cammino lento",
        description: "Microavventura privata con piccolo gruppo e follow-up dopo l'esperienza.",
        details: "Pensata come esperienza discreta, visibile pubblicamente solo quando e pronta per essere raccontata.",
        icon: "Mappa",
        month: "MAG",
        day: "28",
        weekday: "Giovedi",
        date: "28 Maggio 2026",
        time: "20:30 - 23:45",
        brand: "Inside Adventure",
        organizer: "Professionista singolo + piccolo gruppo",
        location: "Valle Intelvi",
        format: "Adventure notte lenta",
        participants: "10 partecipanti",
        duration: "3 ore e 15"
      }
    ]
  end

  def mock_public_services
    [
      {
        id: 201,
        category: "service",
        title: "Valutazione posturale guidata",
        description: "Servizio prenotabile individuale con osservazione, confronto e indicazioni iniziali.",
        details: "Uno spazio prenotabile per chi vuole iniziare da una valutazione chiara e orientarsi nel proprio percorso.",
        icon: "Servizio",
        request_label: "Richiedi appuntamento",
        service_mode: "Singolo",
        price_label: "80€",
        brand: "PosturaCorretta",
        organizer: "Professionista singolo",
        location: "Milano, studio centrale",
        format: "Servizio su prenotazione",
        participants: "1 persona",
        duration: "1 ora"
      },
      {
        id: 202,
        category: "service",
        title: "Mobilita articolare e riattivazione",
        description: "Servizio prenotabile per sciogliere tensioni e riattivare il corpo in modo mirato.",
        details: "Una sessione dedicata alla mobilita articolare e alla riattivazione dei recettori, pensata come servizio puntuale.",
        icon: "Prenota",
        request_label: "Richiedi appuntamento",
        service_mode: "Pacchetto 4 incontri",
        price_label: "260€",
        brand: "PosturaCorretta",
        organizer: "Professionista singolo",
        location: "Como, studio lago",
        format: "Servizio corpo singolo",
        participants: "1 persona",
        duration: "1 ora"
      }
    ]
  end

  def mock_public_courses
    [
      {
        id: 301,
        category: "course",
        title: "Corso settimanale postura e fisiologia",
        description: "Percorso settimanale a iscrizione per capire il corpo e lavorare con continuita.",
        details: "Un corso ricorrente, pensato per chi vuole seguire un ciclo di incontri e non una singola esperienza.",
        icon: "Corso",
        month: "MAG",
        day: "21",
        weekday: "Mercoledi",
        date: "Dal 21 Maggio 2026",
        time: "19:00 - 20:30",
        brand: "PosturaCorretta",
        organizer: "Professionista singolo + gruppo",
        location: "Milano, sala studio",
        format: "Corso settimanale",
        sessions: [
          { label: "Incontro 1", date: "21 Maggio 2026", time: "19:00 - 20:30", location: "Milano, sala studio" },
          { label: "Incontro 2", date: "28 Maggio 2026", time: "19:00 - 20:30", location: "Milano, sala studio" },
          { label: "Incontro 3", date: "4 Giugno 2026", time: "19:00 - 20:30", location: "Milano, sala studio" }
        ],
        participants: "16 iscritti",
        duration: "6 settimane"
      },
      {
        id: 302,
        category: "course",
        title: "Inside Adventure training group",
        description: "Ciclo settimanale per chi vuole allenare corpo, esperienza e relazione con il territorio.",
        details: "Una formula di gruppo, con iscrizione settimanale o a ciclo, per chi vuole continuita piu che evento singolo.",
        icon: "Settimana",
        month: "MAG",
        day: "26",
        weekday: "Lunedi",
        date: "Dal 26 Maggio 2026",
        time: "18:30 - 20:00",
        brand: "Inside Adventure",
        organizer: "Organizzazione di gruppo",
        location: "Lecco, base outdoor",
        format: "Corso settimanale outdoor",
        sessions: [
          { label: "Incontro 1", date: "26 Maggio 2026", time: "18:30 - 20:00", location: "Lecco, base outdoor" },
          { label: "Incontro 2", date: "2 Giugno 2026", time: "18:30 - 20:00", location: "Lecco, base outdoor" },
          { label: "Incontro 3", date: "9 Giugno 2026", time: "18:30 - 20:00", location: "Lecco, base outdoor" }
        ],
        participants: "20 iscritti",
        duration: "8 settimane"
      }
    ]
  end
end
