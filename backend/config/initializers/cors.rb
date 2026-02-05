# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow localhost origins
    if Rails.env.development?
      origins 'http://localhost:5173', 
              'http://127.0.0.1:5173',
              'localhost:5173'
    else
      # In production, only allow your frontend domain
      origins ENV.fetch('FRONTEND_URL', 'https://justinnegron.dev')
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false,  # Changed to false for now (simpler)
      max_age: 86400
  end
end