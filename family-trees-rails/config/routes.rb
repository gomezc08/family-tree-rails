Rails.application.routes.draw do
  resources :people
  root "home#index"
  get "home/about"
  get "home/profile"
  get "home/sign_out"
end
