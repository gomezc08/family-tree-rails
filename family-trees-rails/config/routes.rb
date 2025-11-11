Rails.application.routes.draw do
  devise_for :users
  resources :people
  root "home#index"
  get "home/about"
  get "home/profile"
end
