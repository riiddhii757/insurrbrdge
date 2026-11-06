Rails.application.routes.draw do
  root "home#index"
  get "up" => "rails/health#show", as: :health_check

  get "sign_up", to: "registrations#new", as: :sign_up
  post "sign_up", to: "registrations#create"
  get "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  resource :workspace, only: :show, controller: "workspace"
end
