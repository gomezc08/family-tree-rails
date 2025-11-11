Rails.application.routes.draw do
  root "home#index"
  get "home/about"
  get "home/profile"
  get "home/sign_out"
end
