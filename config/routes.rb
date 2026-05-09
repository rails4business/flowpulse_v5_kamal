Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[ new create ]
  resources :passwords, param: :token
  get "home/index"
  get "dashboard" => "home#dashboard"
  get "elenco_pagine" => "home#elenco_pagine"
  get "eventi" => "public_events#index", as: :eventi
  get "eventi/:id" => "public_events#show", as: :evento
  get "progetti" => "home#progetti"
  get "lavoro" => "home#lavoro"
  get "salute" => "home#salute"
  get "risorse" => "resources#index", as: :resources
  get "risorse/:id" => "resources#show", as: :resource
  get "pagine/:slug" => "view_pages#show", as: :view_page
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")

  root "home#index"
end
