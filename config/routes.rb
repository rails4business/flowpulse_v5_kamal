Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[new create]
  resources :passwords, param: :token

  # Public Routes
  root "domains#show"
  resources :nodes, only: [:show]
  get "esperienze" => "public_events#index", as: :esperienze
  get "esperienze/:id" => "public_events#show", as: :esperienza
  get "flowpulse" => "landing#flowpulse", as: :flowpulse
  get "markpostura" => "landing#markpostura", as: :markpostura
  get "markposturaold" => "landing#markpostura_old", as: :markposturaold
  get "markposturastory" => "landing#markposturastory", as: :markposturastory
  get "posturacorretta" => "brands/posturacorretta#home", as: :posturacorretta
  get "posturacorretta/accademia" => "brands/posturacorretta#accademia", as: :posturacorretta_accademia
  get "posturacorretta/percorso" => "brands/posturacorretta#percorso", as: :posturacorretta_percorso
  get "posturacorretta/metodiche" => "brands/posturacorretta#metodiche", as: :posturacorretta_metodiche
  get "posturacorretta/metodiche/:slug" => "brands/posturacorretta#metodica", as: :posturacorretta_metodica
  get "posturacorretta/professionisti" => "brands/posturacorretta#professionisti", as: :posturacorretta_professionisti
  get "posturacorretta/contenuti" => "brands/posturacorretta#contenuti", as: :posturacorretta_contenuti
  get "posturacorretta/contenuti/:slug" => "brands/posturacorretta#articolo", as: :posturacorretta_articolo
  get "posturacorretta/eventi" => "brands/posturacorretta#eventi", as: :posturacorretta_eventi
  get "posturacorretta/libro" => "brands/posturacorretta#libro", as: :posturacorretta_libro
  get "posturacorretta/filosofia" => redirect("/posturacorretta/libro", status: 301), as: :posturacorretta_filosofia
  get "posturacorretta/progetti" => "brands/posturacorretta#progetti", as: :posturacorretta_progetti
  get "posturacorretta/progetti/:slug" => "brands/posturacorretta#progetto", as: :posturacorretta_progetto
  get "posturacorretta/impegno" => "brands/impegno/commitments#index", defaults: { brand_scope: "posturacorretta" }, as: :posturacorretta_impegno
  resources :data_commitments, controller: "brands/impegno/commitments", only: %i[index create update destroy], path: "impegni" do
    collection do
      post :complete_step
    end
    member do
      patch :start
      patch :complete
    end
  end
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

  # Dashboard utente loggato
  get "dashboard" => "home#dashboard", as: :dashboard
  get "dashboard/viaggiatore" => "pages#viaggiatori", as: :viaggiatori
  patch "dashboard_role" => "home#dashboard_role", as: :dashboard_role
  patch "dashboard_channel" => "home#dashboard_channel", as: :dashboard_channel
  resources :traveler_subscriptions, only: [:create, :destroy]
  resource :profile, only: [:show]

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
    resources :risorse, controller: "/resources", only: [:index, :show]
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
