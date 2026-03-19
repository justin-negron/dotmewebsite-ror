# Verifies that requests come through CloudFront by checking
# the X-CloudFront-Secret header against ENV["CLOUDFRONT_SECRET"].
# Skips verification for health check paths and in non-production environments.
class CloudfrontSecretMiddleware
  SKIP_PATHS = %w[/up /health].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless Rails.env.production?

    path = Rack::Utils.clean_path_info(env[Rack::PATH_INFO])
    return @app.call(env) if SKIP_PATHS.include?(path)

    expected = ENV["CLOUDFRONT_SECRET"]
    return @app.call(env) if expected.blank?

    actual = env["HTTP_X_CLOUDFRONT_SECRET"]

    if ActiveSupport::SecurityUtils.secure_compare(actual.to_s, expected)
      @app.call(env)
    else
      [403, { "content-type" => "application/json" }, ['{"error":"Forbidden"}']]
    end
  end
end
