require 'rails_helper'

RSpec.describe 'Api::V1::BlogPosts', type: :request do
  describe 'GET /api/v1/blog_posts' do
    it 'returns only published blog posts' do
      published_posts = create_list(:blog_post, 3, :published)
      draft_post = create(:blog_post, :draft)
      
      get '/api/v1/blog_posts'
      
      expect(response).to have_http_status(:success)
      expect(json[:success]).to be true
      expect(json_data.size).to eq(3)
    end
    
    it 'filters by tag' do
      # Create posts with specific tags (don't use let! here to avoid interference)
      tagged_post = create(:blog_post, :published, tags: ['Ruby', 'Rails'])
      other_post = create(:blog_post, :published, tags: ['JavaScript'])
      
      get '/api/v1/blog_posts?tag=Ruby'
      
      expect(response).to have_http_status(:success)
      expect(json_data.size).to eq(1)
      expect(json_data.first[:id]).to eq(tagged_post.id)
    end
    
    it 'includes pagination meta' do
      get '/api/v1/blog_posts'
      
      expect(json_meta).to include(:current_page, :total_pages, :total_count)
    end
    
    it 'orders by most recent first' do
      oldest = create(:blog_post, :published, published_at: 3.days.ago)
      newest = create(:blog_post, :published, published_at: 1.day.ago)
      
      get '/api/v1/blog_posts'
      
      expect(json_data.first[:id]).to eq(newest.id)
    end
  end
  
  describe 'GET /api/v1/blog_posts/:slug' do
    let(:blog_post) { create(:blog_post, :published) }
    
    it 'returns a specific blog post by slug' do
      get "/api/v1/blog_posts/#{blog_post.slug}"
      
      expect(response).to have_http_status(:success)
      expect(json_data[:slug]).to eq(blog_post.slug)
      expect(json_data[:title]).to eq(blog_post.title)
    end
    
    it 'increments view count' do
      expect {
        get "/api/v1/blog_posts/#{blog_post.slug}"
      }.to change { blog_post.reload.view_count }.by(1)
    end
    
    it 'returns 404 for non-existent slug' do
      get '/api/v1/blog_posts/non-existent-slug'
      
      expect(response).to have_http_status(:not_found)
      expect(json[:success]).to be false
    end
    
    it 'returns 404 for draft posts' do
      draft = create(:blog_post, :draft)
      get "/api/v1/blog_posts/#{draft.slug}"
      
      expect(response).to have_http_status(:not_found)
    end
  end
end