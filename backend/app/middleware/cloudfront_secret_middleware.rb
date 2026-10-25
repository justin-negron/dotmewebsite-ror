# Verifies that requests come through CloudFront by checking
# the X-CloudFront-Secret header against ENV["CLOUDFRONT_SECRET"].
# Skips verification for health check paths and in non-production environments.
# A blank secret rejects everything rather than letting everything through.
class CloudfrontSecretMiddleware
  SKIP_PATHS = %w[/up /health].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless Rails.env.production?

    path = Rack::Utils.clean_path_info(env[Rack::PATH_INFO])
    return @app.call(env) if SKIP_PATHS.include?(path)

    expected = ENV["CLOUDFRONT_SECRET"].to_s
    actual = env["HTTP_X_CLOUDFRONT_SECRET"].to_s

    if expected.present? && ActiveSupport::SecurityUtils.secure_compare(actual, expected)
      @app.call(env)
    else
      # Built per request: outer middleware (Rack::Head, RequestId, the security
      # headers) writes into the triple it gets back, so a shared one leaks headers
      # between requests and raises FrozenError on HEAD.
      [ 403, { "content-type" => "application/json" }, [ '{"error":"Forbidden"}' ] ]
    end
  end
end
