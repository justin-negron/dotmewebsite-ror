# frozen_string_literal: true

# Security headers for API responses.
# force_ssl already handles Strict-Transport-Security in production.
Rails.application.config.middleware.insert_after ActionDispatch::Callbacks,
  Class.new {
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      headers["X-Content-Type-Options"] = "nosniff"
      headers["X-Frame-Options"] = "DENY"
      headers["X-Permitted-Cross-Domain-Policies"] = "none"
      headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
      headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"

      [status, headers, body]
    end
  }
