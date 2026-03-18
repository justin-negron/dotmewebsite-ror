require 'rails_helper'

RSpec.describe 'Api::V1::Admin::BlogPosts', type: :request do
  let!(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }

  describe 'GET /api/v1/admin/blog_posts' do
    before do
      create_list(:blog_post, 2, :published)
      create(:blog_post, :draft)
    end

    it 'returns all blog posts including drafts' do
      get '/api/v1/admin/blog_posts', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(3)
    end

    it 'includes pagination meta' do
      get '/api/v1/admin/blog_posts', headers: headers, as: :json

      expect(json_meta).to include(:current_page, :total_pages, :total_count)
    end

    it 'returns 401 without auth' do
      get '/api/v1/admin/blog_posts', as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/admin/blog_posts/:id' do
    let!(:blog_post) { create(:blog_post) }

    it 'returns the blog post by id' do
      get "/api/v1/admin/blog_posts/#{blog_post.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:id]).to eq(blog_post.id)
      expect(json_data[:title]).to eq(blog_post.title)
    end

    it 'returns draft posts (unlike public endpoint)' do
      draft = create(:blog_post, :draft)

      get "/api/v1/admin/blog_posts/#{draft.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:published]).to be false
    end
  end

  describe 'POST /api/v1/admin/blog_posts' do
    let(:valid_params) do
      {
        blog_post: {
          title: 'New Blog Post',
          content: 'This is the content of the new blog post with enough text.',
          tags: ['Ruby', 'Rails']
        }
      }
    end

    it 'creates a blog post and returns 201' do
      expect {
        post '/api/v1/admin/blog_posts', params: valid_params, headers: headers, as: :json
      }.to change(BlogPost, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_data[:title]).to eq('New Blog Post')
      expect(json_data[:slug]).to eq('new-blog-post')
    end

    it 'returns 422 for invalid params' do
      post '/api/v1/admin/blog_posts',
           params: { blog_post: { content: 'No title' } },
           headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'PATCH /api/v1/admin/blog_posts/:id' do
    let!(:blog_post) { create(:blog_post, title: 'Old Title') }

    it 'updates the blog post' do
      patch "/api/v1/admin/blog_posts/#{blog_post.id}",
            params: { blog_post: { title: 'Updated Title' } },
            headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:title]).to eq('Updated Title')
    end
  end

  describe 'DELETE /api/v1/admin/blog_posts/:id' do
    let!(:blog_post) { create(:blog_post) }

    it 'deletes the blog post' do
      expect {
        delete "/api/v1/admin/blog_posts/#{blog_post.id}", headers: headers, as: :json
      }.to change(BlogPost, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_data[:message]).to eq('Blog post deleted')
    end
  end

  describe 'PATCH /api/v1/admin/blog_posts/:id/publish' do
    let!(:blog_post) { create(:blog_post, :draft) }

    it 'publishes the blog post' do
      patch "/api/v1/admin/blog_posts/#{blog_post.id}/publish", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:published]).to be true
      expect(json_data[:published_at]).to be_present
      expect(blog_post.reload.published).to be true
    end
  end

  describe 'PATCH /api/v1/admin/blog_posts/:id/unpublish' do
    let!(:blog_post) { create(:blog_post, :published) }

    it 'unpublishes the blog post' do
      patch "/api/v1/admin/blog_posts/#{blog_post.id}/unpublish", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:published]).to be false
      expect(json_data[:published_at]).to be_nil
      expect(blog_post.reload.published).to be false
    end
  end
end
