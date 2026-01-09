Rails.application.routes.draw do
  # Plan page (main view)
  get "plan", to: "plan#show", as: :plan
  root "plan#show"

  # Tasks API
  resources :tasks, only: [:create, :update, :destroy] do
    member do
      patch :complete
      patch :uncomplete
      patch :archive
      patch :move
      patch :reorder
    end
  end

  # Time blocks API
  resources :time_blocks, only: [:update]

  # Daily goals API
  resources :daily_goals, only: [:update], param: :date

  # OAuth callbacks
  get "/auth/google_oauth2/callback", to: "oauth_callbacks#google"
  get "/auth/failure", to: "oauth_callbacks#failure"

  # Calendar events API
  get "/calendar/events", to: "calendar#events"

  # Basecamp OAuth
  get "/auth/basecamp/callback", to: "oauth_callbacks#basecamp"

  # Basecamp sync
  post "/basecamp/sync", to: "basecamp#sync"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
