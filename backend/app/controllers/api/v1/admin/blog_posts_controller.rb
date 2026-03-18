module Api
  module V1
    module Admin
      class BlogPostsController < BaseController
        before_action :set_blog_post, only: [:show, :update, :destroy, :publish, :unpublish]

        def index
          blog_posts = BlogPost.recent
          blog_posts = blog_posts.page(params[:page]).per(params[:per_page] || 20)
          render_success(BlogPostResource.new(blog_posts).to_h, meta: pagination_meta(blog_posts))
        end

        def show
          render_success(BlogPostResource.new(@blog_post).to_h)
        end

        def create
          blog_post = BlogPost.create!(blog_post_params)
          render_success(BlogPostResource.new(blog_post).to_h, status: :created)
        end

        def update
          @blog_post.update!(blog_post_params)
          render_success(BlogPostResource.new(@blog_post).to_h)
        end

        def destroy
          @blog_post.destroy!
          render_success({ message: 'Blog post deleted' })
        end

        def publish
          @blog_post.update!(published: true)
          render_success(BlogPostResource.new(@blog_post).to_h)
        end

        def unpublish
          @blog_post.update!(published: false, published_at: nil)
          render_success(BlogPostResource.new(@blog_post).to_h)
        end

        private

        def set_blog_post
          @blog_post = BlogPost.find(params[:id])
        end

        def blog_post_params
          params.require(:blog_post).permit(
            :title, :slug, :content, :excerpt, :published, tags: []
          )
        end
      end
    end
  end
end
