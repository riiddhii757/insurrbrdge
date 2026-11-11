Rails.application.routes.draw do
  root "home#index"
  get "up" => "rails/health#show", as: :health_check

  get "sign_up", to: "registrations#new", as: :sign_up
  post "sign_up", to: "registrations#create"
  get "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  get "password/forgot", to: "password_resets#new", as: :new_password_reset
  post "password/forgot", to: "password_resets#create", as: :password_resets
  get "password/reset/:token", to: "password_resets#edit", as: :edit_password_reset
  patch "password/reset/:token", to: "password_resets#update", as: :password_reset

  resource :workspace, only: :show, controller: "workspace"
  resources :customers
  resources :insurance_submissions, only: %i[index show new create] do
    post :submit, on: :member
  end
end
