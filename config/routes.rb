Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[new create]
  resources :passwords, param: :token

  # Public Routes
  root "domains#show"
  get "esperienze" => "public_events#index", as: :esperienze
  get "esperienze/:id" => "public_events#show", as: :esperienza
  get "markpostura" => "pages#markpostura", as: :markpostura
  get "markposturaold" => "pages#markpostura_old", as: :markposturaold
  get "markposturastory" => "pages#markposturastory", as: :markposturastory
    get "posturacorretta" => "pages#posturacorretta", as: :posturacorretta

  # Dashboard utente loggato
  get "dashboard" => "home#dashboard", as: :dashboard
  get "dashboard/viaggiatore" => "pages#viaggiatori", as: :viaggiatori
  patch "dashboard_role" => "home#dashboard_role", as: :dashboard_role

  # Area Admin / Superadmin
  namespace :admin do
    get "dashboard" => "home#dashboard", as: :dashboard
    get "elenco_pagine" => "home#elenco_pagine", as: :elenco_pagine
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

    get "mvp_home" => "pages#mvp_home"
    get "mondi" => "pages#mari"
    get "progetti" => "home#progetti"
    get "lavoro" => "home#lavoro"
    get "salute" => "home#salute"
    get "pagine/:slug" => "view_pages#show", as: :view_page
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
