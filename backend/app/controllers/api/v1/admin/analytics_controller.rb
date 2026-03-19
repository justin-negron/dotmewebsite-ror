module Api
  module V1
    module Admin
      class AnalyticsController < BaseController
        def dashboard
          days = (params[:days] || 30).to_i.clamp(1, 365)

          render_success({
            total_views: PageView.where('created_at >= ?', days.days.ago).count,
            unique_visitors: PageView.unique_visitors(days),
            views_by_date: PageView.views_by_date(days).transform_keys(&:to_s),
            popular_pages: PageView.popular_pages(10).map { |pv| { path: pv.path, count: pv.view_count } },
            recent_views: PageViewResource.new(PageView.recent.limit(20)).to_h,
            summary: {
              total_projects: Project.count,
              total_blog_posts: BlogPost.count,
              published_blog_posts: BlogPost.published.count,
              draft_blog_posts: BlogPost.draft.count,
              total_contacts: Contact.count,
              unread_contacts: Contact.unread.count
            }
          })
        end
      end
    end
  end
end
