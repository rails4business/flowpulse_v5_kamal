Rails.application.routes.draw do
  get "posturacorrettastart", to: "posturacorrettastart#index"
  get "posturacorrettastart/primo_mese", to: "posturacorrettastart#one_month", as: :posturacorrettastart_primo_mese
  get "posturacorrettastart/primo_mese/:chapter", to: "posturacorrettastart#one_month", as: :posturacorrettastart_primo_mese_chapter
  get "posturacorrettastart/1mese", to: redirect("/posturacorrettastart/primo_mese", status: 301)
  resource :session
  resource :site_selection, only: :create
  resources :users, only: %i[new create]
  resources :passwords, param: :token

  # Public Routes
  constraints ->(request) { request.host == "posturacorretta.org" } do
    get "/", to: "posturacorretta_seme#index", as: :posturacorretta_domain_root
  end
  constraints ->(request) { %w[ilgiardinodelcorpo.it www.ilgiardinodelcorpo.it].include?(request.host) } do
    get "/", to: "landing#giardino_del_corpo", as: :giardino_del_corpo_domain_root
  end
  root "domains#show"
  resources :nodes, only: [:show]
  get "eventi" => "public_events#index", as: :eventi
  get "eventi/:id" => "public_events#show", as: :evento
  get "esperienze" => redirect("/eventi", status: 301), as: :esperienze
  get "esperienze/:id" => redirect("/eventi/%{id}", status: 301), as: :esperienza
  get "flowpulse" => "landing#flowpulse", as: :flowpulse
  get "flowpulse/contenuti" => "landing#flowpulse_contents", as: :flowpulse_contents
  get "flowpulse/contenuti/:slug" => "landing#flowpulse_content", as: :flowpulse_content
  get "rails4b" => "landing#rails4b", as: :rails4b
  get "cantachetipassa" => "landing#cantachetipassa", as: :cantachetipassa
  get "il-giardino-del-corpo" => "landing#giardino_del_corpo", as: :giardino_del_corpo
  get "giardino-del-corpo" => redirect("/il-giardino-del-corpo", status: 301)
  direct(:il_giardino_del_corpo) { "/il-giardino-del-corpo" }
  get "percorso-integrato" => "brands/percorso_integrato#index", as: :percorso_integrato
  get "percorso-integrato/professionisti" => "brands/percorso_integrato#professionals", as: :percorso_integrato_professionals
  get "percorso-integrato/professionisti/:slug" => "brands/percorso_integrato#professional", as: :percorso_integrato_professional
  get "percorso-integrato/luoghi" => "brands/percorso_integrato#places", as: :percorso_integrato_places
  get "markpostura" => "landing#markpostura", as: :markpostura
  get "markpostura/eventi" => "landing#markpostura_events", as: :markpostura_events
  get "markpostura/contenuti" => "landing#markpostura_contents", as: :markpostura_contents
  get "markpostura/contenuti/:slug" => "landing#markpostura_content", as: :markpostura_content
  get "markposturaold" => "landing#markpostura_old", as: :markposturaold
  get "markposturastory" => "landing#markposturastory", as: :markposturastory
  get "posturacorretta" => "posturacorretta_seme#index", as: :posturacorretta
  get "posturacorretta/corsi/:corso" => "posturacorretta_seme#course", as: :posturacorretta_course
  get "posturacorretta/corsi/:corso/lezioni" => "posturacorretta_seme#programma", as: :posturacorretta_course_lessons
  get "posturacorretta/corsi/:corso/lezioni/:attivita" => "posturacorretta_seme#programma", as: :posturacorretta_course_lesson
  get "posturacorretta/corsi/:corso/capitoli" => "posturacorretta_seme#percorso_educativo", as: :posturacorretta_course_chapters
  get "posturacorretta/corsi/:corso/capitoli/:capitolo" => "posturacorretta_seme#percorso_educativo", as: :posturacorretta_course_chapter
  get "posturacorretta/programma" => "posturacorretta_seme#legacy_programma", as: :posturacorretta_programma
  get "posturacorretta/percorso-educativo" => "posturacorretta_seme#legacy_percorso_educativo", as: :posturacorretta_percorso_educativo
  get "posturacorretta/tre-progetti" => "brands/posturacorretta#three_projects", as: :posturacorretta_three_projects
  get "posturacorretta/seme" => "posturacorretta_seme#show", as: :posturacorretta_seme
  get "posturacorretta/seme/percorso" => "posturacorretta_seme#percorso", as: :posturacorretta_seme_percorso
  get "posturacorretta/seme/percorsi-integrati" => "posturacorretta_seme#integrated_paths", as: :posturacorretta_seme_integrated_paths
  get "posturacorretta/seme/dashboard/studente" => "posturacorretta_seme#dashboard_student", as: :posturacorretta_seme_student_dashboard
  get "posturacorretta/dashboard" => "posturacorretta_seme#dashboard_student", as: :posturacorretta_student_dashboard
  get "posturacorretta/dashboard/appuntamenti" => "posturacorretta_seme#dashboard_appointments", as: :posturacorretta_student_appointments
  get "posturacorretta/seme/dashboard/insegnante" => "posturacorretta_seme#dashboard_teacher", as: :posturacorretta_seme_teacher_dashboard
  get "posturacorretta/primo-mese" => "brands/posturacorretta#primo_mese", as: :posturacorretta_primo_mese
  get "posturacorretta/guida" => "brands/posturacorretta#guide", as: :posturacorretta_guida
  get "posturacorretta/accademia" => "brands/posturacorretta#accademia", as: :posturacorretta_accademia
  get "posturacorretta/accademia/recensioni" => "brands/posturacorretta#accademia_recensioni", as: :posturacorretta_accademia_recensioni
  get "posturacorretta/accademia/:slug" => "brands/posturacorretta#accademia_modulo", as: :posturacorretta_accademia_modulo
  get "posturacorretta/percorso" => redirect("/percorso-integrato", status: 301), as: :posturacorretta_percorso
  get "posturacorretta/percorso/come-funziona" => "brands/posturacorretta#percorso_come_funziona", as: :posturacorretta_percorso_come_funziona
  get "posturacorretta/percorsi-sul-territorio" => "brands/posturacorretta#percorsi_sul_territorio", as: :posturacorretta_percorsi_sul_territorio
  get "posturacorretta/metodiche" => "brands/posturacorretta#metodiche", as: :posturacorretta_metodiche
  get "posturacorretta/metodiche/:slug" => "brands/posturacorretta#metodica", as: :posturacorretta_metodica
  get "posturacorretta/professionisti" => "brands/posturacorretta#professionisti", as: :posturacorretta_professionisti
  get "posturacorretta/professionisti/:slug" => "brands/posturacorretta#professionista", as: :posturacorretta_professionista
  get "posturacorretta/insegnanti" => "brands/posturacorretta#insegnanti", as: :posturacorretta_insegnanti
  get "posturacorretta/contenuti" => "brands/posturacorretta#contenuti", as: :posturacorretta_contenuti
  get "posturacorretta/corsi" => "brands/posturacorretta#corsi", as: :posturacorretta_corsi
  get "posturacorretta/contenuti/:slug" => "brands/posturacorretta#articolo", as: :posturacorretta_articolo
  get "posturacorretta/eventi" => "brands/posturacorretta#eventi", as: :posturacorretta_eventi
  get "posturacorretta/eventi/:id" => "posturacorretta_data_events#show", as: :posturacorretta_data_event
  post "posturacorretta/eventi/:id/prenotazione" => "posturacorretta_data_events#create_booking", as: :book_posturacorretta_data_event
  get "posturacorretta/dash" => "brands/posturacorretta#dash", as: :posturacorretta_dash
  get "posturacorretta/libri" => "brands/posturacorretta#libri", as: :posturacorretta_libri
  get "posturacorretta/visione" => redirect("/posturacorretta/guida?sezione=progetto&capitolo=visione", status: 301), as: :posturacorretta_visione
  get "posturacorretta/libro" => redirect("/posturacorretta/visione", status: 301), as: :posturacorretta_libro
  get "posturacorretta/filosofia" => redirect("/posturacorretta/visione", status: 301), as: :posturacorretta_filosofia
  get "posturacorretta/progetti" => "brands/posturacorretta#progetti", as: :posturacorretta_progetti
  get "posturacorretta/progetti/:slug" => "brands/posturacorretta#progetto", as: :posturacorretta_progetto
  get "posturacorretta/impegno" => "brands/impegno/home#index", defaults: { brand: "posturacorretta" }, as: :posturacorretta_impegno
  resources :data_commitments, controller: "brands/impegno/commitments", only: %i[create update destroy], path: "impegni" do
    collection do
      post :complete_step
    end
    member do
      patch :start
      patch :complete
    end
  end
  get "impegni" => redirect("/impegno?area=user&view=agenda"), as: :legacy_data_commitments
  get "posturacorretta/collabora" => "brands/posturacorretta#collabora", as: :posturacorretta_collabora
  get "posturacorretta/collabora/professionisti" => "brands/posturacorretta#collabora_professionisti", as: :posturacorretta_collabora_professionisti
  get "posturacorretta/collabora/professionisti/:slug" => "brands/posturacorretta#collabora_professionisti_guida", as: :posturacorretta_collabora_professionisti_guida
  get "posturacorretta/collabora/digital" => "brands/posturacorretta#collabora_digital", as: :posturacorretta_collabora_digital
  get "generaimpresa" => "brands/genera_impresa#index", as: :genera_impresa
  get "generaimpresa/brand/:slug" => "brands/genera_impresa#brand", as: :genera_impresa_brand
  get "generaimpresa/progetti/:slug" => "brands/genera_impresa#project", as: :genera_impresa_project
  get "brands/svuotamente" => "brands/svuotamente#index", as: :svuotamente
  get "svuotamente" => redirect("/brands/svuotamente", status: 301), as: :legacy_svuotamente
  get "impegno" => "brands/impegno/home#index", as: :impegno
  get "impegno/agenda" => "brands/impegno/commitments#index", as: :impegno_agenda
  patch "impegno/requests/:id/reject" => "brands/impegno/requests#reject", as: :reject_impegno_request
  patch "impegno/requests/:id/confirm" => "brands/impegno/requests#confirm", as: :confirm_impegno_request
  patch "impegno/requests/:id/cancel-confirmation" => "brands/impegno/requests#cancel_confirmation", as: :cancel_confirmed_impegno_request
  patch "impegno/requests/:id/withdraw" => "brands/impegno/requests#withdraw", as: :withdraw_impegno_request
  resources :impegno_data_events, path: "impegno/data-events", controller: "brands/impegno/data_events", only: %i[index show new create edit update]
  get "impegno/data-events/:data_event_id/days/new" => "brands/impegno/data_event_days#new", as: :new_impegno_data_event_day
  post "impegno/data-events/:data_event_id/days" => "brands/impegno/data_event_days#create", as: :impegno_data_event_days
  get "impegno/data-events/:data_event_id/days/:id/edit" => "brands/impegno/data_event_days#edit", as: :edit_impegno_data_event_day
  patch "impegno/data-events/:data_event_id/days/:id" => "brands/impegno/data_event_days#update", as: :impegno_data_event_day
  get "impegno/data-events/:data_event_id/days/:day_id/sessions/new" => "brands/impegno/data_event_sessions#new", as: :new_impegno_data_event_session
  post "impegno/data-events/:data_event_id/days/:day_id/sessions" => "brands/impegno/data_event_sessions#create", as: :impegno_data_event_sessions
  get "impegno/data-events/:data_event_id/days/:day_id/sessions/:id/edit" => "brands/impegno/data_event_sessions#edit", as: :edit_impegno_data_event_session
  patch "impegno/data-events/:data_event_id/days/:day_id/sessions/:id" => "brands/impegno/data_event_sessions#update", as: :impegno_data_event_session
  resources :impegno_contacts, path: "impegno/contacts", controller: "brands/impegno/contacts", as: :impegno_contacts, only: %i[index create edit update destroy]
  resources :impegno_places, path: "impegno/places", controller: "brands/impegno/places", as: :impegno_places, only: %i[index create edit update destroy]

  # Dashboard utente loggato
  get "dashboard" => "home#dashboard", as: :dashboard
  get "dashboard/viaggiatore" => "pages#viaggiatori", as: :viaggiatori
  patch "dashboard_role" => "home#dashboard_role", as: :dashboard_role
  patch "dashboard_channel" => "home#dashboard_channel", as: :dashboard_channel
  resources :traveler_subscriptions, only: [:create, :destroy]
  resource :profile, only: %i[show update] do
    patch :details
  end
  resources :profile_data_commitment_imports, only: [] do
    member do
      patch :accept
      patch :reject
    end
  end

  namespace :creator_world do
    root "dashboard#show"
    resources :role_assignments, only: [:index, :new, :create, :destroy] do
      resources :nodes, except: [:show] do
        member do
          patch :move
          get :tree
        end
      end
    end
  end

  namespace :teacher do
    root "dashboard#show"
  end

  namespace :tutor do
    root "dashboard#show"
  end

  namespace :professional do
    root "dashboard#show"
  end

  # Area Admin / Superadmin
  namespace :admin do
    get "dashboard" => "home#dashboard", as: :dashboard
    post "set_override" => "home#set_override", as: :set_override
    get "elenco_pagine" => "home#elenco_pagine", as: :elenco_pagine
    get "percorso_insegnanti" => "home#percorso_insegnanti", as: :percorso_insegnanti
    get "percorso_insegnanti/fonti/*path" => "didactic_sources#show", as: :didactic_source, format: false
    get "appunti" => "notes#index", as: :notes
    get "appunti/:source/*path" => "notes#show", as: :note
    get "contenuti" => "content_taxonomy#show", as: :content_taxonomy
    get "role_map" => "role_maps#show", as: :role_map
    get "assigned_role_map" => "assigned_role_maps#show", as: :assigned_role_map
    get "assigned_role_map/new" => "assigned_role_maps#new", as: :new_assigned_role_map
    post "assigned_role_map" => "assigned_role_maps#create"
    resources :domains do
      collection do
        get :export
        post :import
      end
    end
    resources :password_reset_requests, only: :index do
      member do
        patch :complete
      end
    end
    resources :data_commitment_imports, only: %i[index create] do
      collection do
        get :export
        post :queue_export
      end
      member { patch :apply }
    end
    resources :risorse, controller: "/resources", only: [:index, :show]
  end

  namespace :sync do
    resources :data_commitment_imports, only: :create
  end

  # Area Demo / Prototipi
  namespace :demo do
    get "mari" => "pages#mari"
    get "viaggiatori" => "pages#viaggiatori"
    get "carta_nautica" => "pages#carta_nautica"

    get "mondi" => "pages#mari"
    get "progetti" => "home#progetti"
    get "lavoro" => "home#lavoro"
    get "salute" => "home#salute"
    get "accademia" => "home#accademia"
    get "pagine/:slug" => "view_pages#show", as: :view_page
  end

  # Libro routes
  get "books/:book_slug" => "libro#index", as: :book
  get "books/:book_slug/gestione/guida" => "libro#guida", as: :book_guida
  get "books/:book_slug/:id" => "libro#show", as: :book_chapter

  get "libro" => "libro#legacy_index", as: :libro
  get "libro/gestione/guida" => "libro#legacy_guida", as: :libro_guida
  get "libro/:id" => "libro#legacy_show", as: :libro_chapter

  get "up" => "rails/health#show", as: :rails_health_check
end
