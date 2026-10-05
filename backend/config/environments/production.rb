require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # ActiveStorage disabled — re-enable when file uploads are needed.
  # config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Single Puma process, so an in-memory cache is enough (also backs Rack::Attack).
  config.cache_store = :memory_store, { size: 32 * 1024 * 1024 }

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # Solid Queue runs inside Puma (see config/puma.rb) and stores jobs in the primary database.
  config.active_job.queue_adapter = :solid_queue

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates (overridden below).

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false


  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [
    ENV.fetch('APP_HOST', 'justinnegron.dev'),
    /.*\.#{Regexp.escape(ENV.fetch('APP_HOST', 'justinnegron.dev'))}/
  ]

  # Skip DNS rebinding protection for health checks and API routes.
  # API access is secured by CloudfrontSecretMiddleware instead.
  config.host_authorization = { exclude: ->(request) {
    request.path.start_with?("/api", "/up", "/health")
  } }

  # Action Mailer configuration
  config.action_mailer.default_url_options = { host: ENV.fetch('FRONTEND_URL', 'https://justinnegron.dev') }

  # Amazon SES API (credentials from AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY via config/initializers/aws.rb).
  config.action_mailer.delivery_method = :ses_v2
  config.action_mailer.ses_v2_settings = { region: ENV.fetch("AWS_REGION", "us-east-1") }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
end
