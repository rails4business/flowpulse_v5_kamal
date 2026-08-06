Rails.application.routes.draw do
  resource :session
  resource :site_selection, only: :create
  resources :users, only: %i[new create]
  resources :passwords, param: :token

  # Public Routes
  root "domains#show"
  resources :nodes, only: [:show]
  get "esperienze" => "public_events#index", as: :esperienze
  get "esperienze/:id" => "public_events#show", as: :esperienza
  get "flowpulse" => "landing#flowpulse", as: :flowpulse
  get "rails4b" => "landing#rails4b", as: :rails4b
  get "markpostura" => "landing#markpostura", as: :markpostura
  get "markposturaold" => "landing#markpostura_old", as: :markposturaold
  get "markposturastory" => "landing#markposturastory", as: :markposturastory
  get "posturacorretta" => "brands/posturacorretta#home", as: :posturacorretta
  get "posturacorretta/accademia" => "brands/posturacorretta#accademia", as: :posturacorretta_accademia
  get "posturacorretta/accademia/recensioni" => "brands/posturacorretta#accademia_recensioni", as: :posturacorretta_accademia_recensioni
  get "posturacorretta/accademia/:slug" => "brands/posturacorretta#accademia_modulo", as: :posturacorretta_accademia_modulo
  get "posturacorretta/percorso" => "brands/posturacorretta#percorso", as: :posturacorretta_percorso
  get "posturacorretta/percorsi-sul-territorio" => "brands/posturacorretta#percorsi_sul_territorio", as: :posturacorretta_percorsi_sul_territorio
  get "posturacorretta/metodiche" => "brands/posturacorretta#metodiche", as: :posturacorretta_metodiche
  get "posturacorretta/metodiche/:slug" => "brands/posturacorretta#metodica", as: :posturacorretta_metodica
  get "posturacorretta/professionisti" => "brands/posturacorretta#professionisti", as: :posturacorretta_professionisti
  get "posturacorretta/professionisti/:slug" => "brands/posturacorretta#professionista", as: :posturacorretta_professionista
  get "posturacorretta/contenuti" => "brands/posturacorretta#contenuti", as: :posturacorretta_contenuti
  get "posturacorretta/contenuti/:slug" => "brands/posturacorretta#articolo", as: :posturacorretta_articolo
  get "posturacorretta/eventi" => "brands/posturacorretta#eventi", as: :posturacorretta_eventi
  get "posturacorretta/visione" => "brands/posturacorretta#libro", as: :posturacorretta_visione
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
