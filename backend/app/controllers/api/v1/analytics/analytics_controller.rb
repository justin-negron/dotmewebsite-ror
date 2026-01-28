module Api
  module V1
    module Analytics
      class AnalyticsController < BaseController
        def track
          @page_view = PageView.create!(page_view_params)
          
          render_success(
            { message: 'Page view tracked' },
            status: :created
          )
        end
        
        private
        
        def page_view_params
          {
            path: params[:path],
            user_agent: request.user_agent,
            ip_address: request.remote_ip,
            referrer: request.referer
          }
        end
      end
    end
  end
end