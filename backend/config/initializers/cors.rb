# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# Origins the API accepts cross-origin requests from. In development the Vite
# dev server may run on any localhost port; everywhere else it is the single
# configured frontend origin.
module CorsOrigins
  DEVELOPMENT = %r{\Ahttp://(localhost|127\.0\.0\.1):\d+\z}

  def self.allowed
    Rails.env.development? ? DEVELOPMENT : ENV.fetch("FRONTEND_URL", "https://justinnegron.dev")
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins CorsOrigins.allowed

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true,  # Required for httpOnly refresh token cookie
      max_age: 3600
  end
end
