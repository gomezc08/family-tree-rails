Rails.application.routes.draw do
  devise_for :users

  resources :users, only: [:show, :edit, :update] do
    # Routes for user profile management - no index (viewing all users)
  end

  resources :relationships do
    collection do
      get :pending
    end
    member do
      patch :approve
      patch :reject
    end
  end

  # Family tree routes
  root "family_trees#show"
  get 'family_tree', to: 'family_trees#show', as: :family_tree

  get "home/about"
  get "home/profile"
end
