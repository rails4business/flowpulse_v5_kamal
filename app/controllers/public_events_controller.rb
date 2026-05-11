class PublicEventsController < ApplicationController
  skip_before_action :require_authentication, only: [:index, :show]

  TABS = {
    "eventi" => { label: "Eventi", internal: false },
    "servizi" => { label: "Servizi", internal: false },
    "corsi" => { label: "Corsi", internal: false },
    "percorsi" => { label: "Percorsi", internal: false }
  }.freeze

  def index
    @tabs = visible_tabs
    @active_tab = normalized_tab(params[:tab])
    @items = items_for(@active_tab)
  end

  def show
    @event = mock_public_event(params[:id])
    redirect_to esperienze_path unless @event
  end

  private

  def visible_tabs
    TABS
  end

  def normalized_tab(tab)
    t = tab.to_s.downcase
    TABS.key?(t) ? t : "eventi"
  end

  def items_for(tab)
    case tab
    when "percorsi"
      mock_public_percorsi
    when "servizi"
      mock_public_services
    when "corsi"
      mock_public_courses
    else
      mock_public_experiences
    end
  end

  def mock_public_percorsi
    [
      {
        id: 401,
        category: "percorso",
        title: "Schiena Sana 360",
        description: "Un percorso completo per eliminare il dolore e ritrovare la mobilita.",
        month: "GIU",
        day: "10",
        weekday: "MER",
        time: "Flessibile",
        brand: "PosturaCorretta",
        sub_brand: "Salute Integrata",
        category_tags: [
          { icon: "💙", label: "Postura", color: "blue" },
          { icon: "🧘", label: "Benessere", color: "purple" }
        ],
        organizer: "Marco",
        location: "Online + Studio",
        event_kind: "Percorso",
        format: "Salute 360",
        participants: "Iscrizioni aperte",
        duration: "12 settimane",
        price_label: "€290"
      }
    ]
  end

  def mock_public_progetti
    [
      {
        id: 501,
        category: "progetto",
        title: "Mappe del Territorio",
        description: "Creazione di itinerari esperienziali tra natura e cultura locale.",
        month: "LUG",
        day: "01",
        weekday: "MER",
        time: "In corso",
        brand: "Flowpulse",
        sub_brand: "Mappe",
        category_tags: [
          { icon: "🗺️", label: "Territorio", color: "slate" },
          { icon: "🌲", label: "Natura", color: "green" }
        ],
        organizer: "Team Flowpulse",
        location: "Vari territori",
        event_kind: "Progetto",
        format: "Collaborativo",
        participants: "8 partner attivi",
        duration: "Annuale",
        price_label: "Bando aperto"
      }
    ]
  end

  def mock_public_experiences
    [
      {
        id: 1,
        category: "experience",
        title: "Postura in Vetta",
        description: "Camminata in montagna con esercizi semplici di postura e recupero.",
        month: "MAG",
        day: "16",
        weekday: "SAB",
        time: "09:30 - 14:00",
        brand: "PosturaCorretta",
        sub_brand: "Stop al Dolore",
        category_tags: [
          { icon: "🚶", label: "Movimento", color: "red" },
          { icon: "🌲", label: "Natura", color: "green" },
          { icon: "💙", label: "Postura", color: "blue" }
        ],
        organizer: "Marco",
        location: "Monte Maddalena",
        event_kind: "Evento",
        format: "PosturaCorretta in vetta",
        participants: "8 posti disponibili",
        duration: "4 ore e 30",
        price_label: "€15"
      },
      {
        id: 2,
        category: "experience",
        title: "Inside Adventure Lab",
        description: "Esplorazione del territorio con attivita di gruppo e condivisione.",
        month: "MAG",
        day: "20",
        weekday: "MER",
        time: "10:00 - 17:30",
        brand: "Inside Adventure",
        sub_brand: "Wild Experience",
        category_tags: [
          { icon: "🌲", label: "Natura", color: "green" },
          { icon: "🛶", label: "Acqua", color: "blue" }
        ],
        organizer: "Team IA",
        location: "Lago di Como",
        event_kind: "Seminario",
        format: "Inside Adventure Lab",
        participants: "24 posti",
        duration: "7 ore e 30",
        price_label: "Gratis"
      },
      {
        id: 3,
        category: "experience",
        title: "Sapienza Visione",
        description: "Parte formativa, confronto e osservazione guidata.",
        month: "GIU",
        day: "01",
        weekday: "LUN",
        time: "18:45 - 21:00",
        brand: "Sapienza Visione",
        sub_brand: "Studio dal vivo",
        category_tags: [
          { icon: "🧘", label: "Meditazione", color: "purple" },
          { icon: "👥", label: "Comunita", color: "slate" }
        ],
        organizer: "Anna",
        location: "Milano, studio centrale",
        event_kind: "Seminario",
        format: "Sapienza Visione live",
        participants: "12 posti",
        duration: "2 ore e 15",
        price_label: "€40"
      }
    ]
  end

  def mock_public_event(id)
    (mock_public_experiences + mock_public_percorsi + mock_public_progetti + mock_public_services + mock_public_courses).find { |e| e[:id].to_s == id.to_s }
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
        season_start: "Autunno",
        season_end: "Primavera",
        time: "19:00 - 20:30",
        brand: "PosturaCorretta",
        organizer: "Professionista singolo + gruppo",
        location: "Milano, sala studio",
        format: "Corso settimanale",
        pricing: "€95/mese oppure €28 a lezione",
        weekly_slots: [
          { day: "Lun", time: "19:00 - 20:30" },
          { day: "Mer", time: "19:00 - 20:30" }
        ],
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
        season_start: "Settembre",
        season_end: "Giugno",
        time: "18:30 - 20:00",
        brand: "Inside Adventure",
        organizer: "Organizzazione di gruppo",
        location: "Lecco, base outdoor",
        format: "Corso settimanale outdoor",
        pricing: "€110/mese oppure €32 a lezione",
        weekly_slots: [
          { day: "Mar", time: "18:30 - 20:00" },
          { day: "Gio", time: "18:30 - 20:00" }
        ],
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
