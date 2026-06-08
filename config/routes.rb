Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[new create]
  resources :passwords, param: :token

  # Public Routes
  root "domains#show"
  get "esperienze" => "public_events#index", as: :esperienze
  get "esperienze/:id" => "public_events#show", as: :esperienza
  get "flowpulse" => "landing#flowpulse", as: :flowpulse
  get "markpostura" => "landing#markpostura", as: :markpostura
  get "markposturaold" => "landing#markpostura_old", as: :markposturaold
  get "markposturastory" => "landing#markposturastory", as: :markposturastory
  get "posturacorretta" => "landing#posturacorretta", as: :posturacorretta

  # Dashboard utente loggato
  get "dashboard" => "home#dashboard", as: :dashboard
  get "dashboard/viaggiatore" => "pages#viaggiatori", as: :viaggiatori
  patch "dashboard_role" => "home#dashboard_role", as: :dashboard_role

  namespace :creator_world do
    root "dashboard#show"
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
    get "elenco_pagine" => "home#elenco_pagine", as: :elenco_pagine
    get "role_map" => "role_maps#show", as: :role_map
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
    get "pagine/:slug" => "view_pages#show", as: :view_page
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
