class Rack::Attack
  # Use Redis in production for consistent rate limiting across processes
  if Rails.env.production?
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
      url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
    )
  end

  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle contact form submissions (5 per 15 minutes per IP)
  throttle("contacts/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/api/v1/contacts" && req.post?
  end

  # Throttle analytics tracking (60 per minute per IP)
  throttle("analytics/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/analytics") && req.post?
  end

  # Block suspicious requests (WordPress probes, path traversal)
  blocklist("block/suspicious") do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
        req.path.include?("/etc/passwd") ||
        req.path.include?("wp-admin") ||
        req.path.include?("wp-login")
    end
  end

  # Custom JSON response for throttled requests
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = (match_data[:period] - (now % match_data[:period])).to_s

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after
    }

    body = {
      success: false,
      message: "Rate limit exceeded. Try again later."
    }.to_json

    [429, headers, [body]]
  end
end
