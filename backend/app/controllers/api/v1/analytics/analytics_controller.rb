module Api
  module V1
    module Analytics
      class AnalyticsController < BaseController
        MAX_FIELD = 512

        throttle to: 20, within: 1.minute, only: :track

        def track
          path = params[:path].to_s.slice(0, MAX_FIELD)
          referrer = params[:referrer].to_s.slice(0, MAX_FIELD)

          unless path.match?(%r{\A/[^\s]*\z})
            return render_error("Invalid path", status: :bad_request)
          end

          PageView.create!(
            path: path,
            user_agent: request.user_agent.to_s.slice(0, MAX_FIELD).presence,
            visitor_hash: PageView.visitor_hash_for(request.remote_ip),
            referrer: referrer.presence
          )

          render_success(
            { message: "Page view tracked" },
            status: :created
          )
        end
      end
    end
  end
end
