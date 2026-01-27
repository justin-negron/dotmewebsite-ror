# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow requests from Vite dev server and local file testing
    if Rails.env.development?
      origins 'http://localhost:5173', 'null'  # 'null' for file:// protocol testing
    else
      origins ENV.fetch('FRONTEND_URL', 'https://justinnegron.me')
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 86400,
      expose: ['Authorization']  # Expose auth headers if needed
  end
  
  # Optional: Allow requests from your production domain
  if Rails.env.production?
    allow do
      origins 'https://justinnegron.me', 'https://www.justinnegron.me'
      
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: true,
        max_age: 86400
    end
  end
end