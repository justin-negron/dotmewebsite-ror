module Api
  module V1
    class BlogPostsController < BaseController
      def index
        @blog_posts = BlogPost.published.recent
        
        # Filter by tag if requested
        @blog_posts = @blog_posts.by_tag(params[:tag]) if params[:tag].present?
        
        # Pagination
        @blog_posts = @blog_posts.page(params[:page]).per(params[:per_page] || 10)
        
        render_success(
          ActiveModelSerializers::SerializableResource.new(@blog_posts).as_json,
          meta: pagination_meta(@blog_posts)
        )
      end
      
      def show
        @blog_post = BlogPost.published.find_by!(slug: params[:slug])
        
        # Increment view count
        @blog_post.increment_view_count!
        
        render_success(
          ActiveModelSerializers::SerializableResource.new(@blog_post).as_json
        )
      end
    end
  end
end