# Validate required environment variables are set
# This prevents the app from starting if critical config is missing

# Required for all environments
REQUIRED_ENV_VARS = %w[
  DATABASE_URL
  REDIS_URL
].freeze

# Additional required for production
REQUIRED_PRODUCTION_ENV_VARS = %w[
  JWT_SECRET
  SECRET_KEY_BASE
  SMTP_ADDRESS
  SMTP_USERNAME
  SMTP_PASSWORD
  FROM_EMAIL
  FRONTEND_URL
].freeze

# Check required variables
missing_vars = REQUIRED_ENV_VARS.reject { |var| ENV[var].present? }

# Add production-specific checks
if Rails.env.production?
  missing_vars += REQUIRED_PRODUCTION_ENV_VARS.reject { |var| ENV[var].present? }
end

# Raise error if any required variables are missing
if missing_vars.any?
  raise "Missing required environment variables: #{missing_vars.join(', ')}\n" \
        "Please check your .env file or environment configuration."
end

# Validate JWT_SECRET length in production
if Rails.env.production? && ENV['JWT_SECRET'].to_s.length < 32
  raise "JWT_SECRET must be at least 32 characters long in production"
end

# Validate SECRET_KEY_BASE length in production
if Rails.env.production? && ENV['SECRET_KEY_BASE'].to_s.length < 64
  raise "SECRET_KEY_BASE must be at least 64 characters long in production"
end