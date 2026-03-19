module Api
  module V1
    module Analytics
      class AnalyticsController < BaseController
        def track
          path = params[:path].to_s.slice(0, 2048)
          referrer = params[:referrer].to_s.slice(0, 2048)

          unless path.match?(%r{\A/[^\s]*\z})
            return render_error('Invalid path', status: :bad_request)
          end

          @page_view = PageView.create!(
            path: path,
            user_agent: request.user_agent,
            ip_address: request.remote_ip,
            referrer: referrer.presence
          )

          render_success(
            { message: 'Page view tracked' },
            status: :created
          )
        end
      end
    end
  end
end