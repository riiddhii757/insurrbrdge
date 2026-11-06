Rails.application.routes.draw do
  root "home#index"
  get "up" => "rails/health#show", as: :health_check
end
