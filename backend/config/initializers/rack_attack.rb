class Rack::Attack
  # Per-action limits on login, refresh, contact and analytics live in the
  # controllers via ActionController rate_limit, which keys on the routed
  # action, not the path.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
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

    [ 429, headers, [ body ] ]
  end
end
