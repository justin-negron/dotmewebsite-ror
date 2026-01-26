Rails.application.routes.draw do
  # Health check endpoint (for AWS ECS health checks)
  get '/health', to: proc { [200, {}, ['OK']] }

  # API namespace
  namespace :api do
    namespace :v1 do
      # Public endpoints
      resources :projects, only: [:index, :show]
      resources :experiences, only: [:index]
      resources :blog_posts, only: [:index, :show], param: :slug
      resources :contacts, only: [:create]
      
      # Analytics
      namespace :analytics do
        post :track, to: 'analytics#track'
      end

      # Admin endpoints (will add authentication later)
      namespace :admin do
        resources :projects
        resources :experiences
        resources :blog_posts do
          member do
            patch :publish
            patch :unpublish
          end
        end
        resources :contacts, only: [:index, :show, :update, :destroy]
        
        # Analytics dashboard
        get 'analytics/dashboard', to: 'analytics#dashboard'
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions
  get "up" => "rails/health#show", as: :rails_health_check
end