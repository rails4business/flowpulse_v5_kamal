Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[ new create ]
  resources :passwords, param: :token
  
  # Area Admin (Solo Superadmin)
  namespace :admin do
    get "dashboard" => "home#dashboard", as: :dashboard
    get "elenco_pagine" => "home#elenco_pagine", as: :elenco_pagine
    resources :risorse, controller: "/resources", only: [:index, :show]
  end

  # Area Demo (Superadmin + Accesso Demo)
  namespace :demo do
    get "mari" => "pages#mari"
    get "viaggiatori" => "pages#viaggiatori"
    get "carta_nautica" => "pages#carta_nautica"
  end

  # Public Routes
  root "pages#mvp_home"
  get "mvp_home" => "pages#mvp_home", as: :mvp_home
  
  get "dashboard" => "home#dashboard", as: :dashboard
  patch "dashboard_role" => "home#dashboard_role", as: :dashboard_role
  
  get "esperienze" => "public_events#index", as: :esperienze
  get "esperienze/:id" => "public_events#show", as: :esperienza
  
  get "progetti" => "home#progetti"
  get "lavoro" => "home#lavoro"
  get "salute" => "home#salute"
  get "mondi" => "pages#mari", as: :mondi
  get "viaggiatori" => "pages#viaggiatori", as: :viaggiatori
  
  get "pagine/:slug" => "view_pages#show", as: :view_page

  get "up" => "rails/health#show", as: :rails_health_check
end
