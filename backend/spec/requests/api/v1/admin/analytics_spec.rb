require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Analytics', type: :request do
  let!(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }

  describe 'GET /api/v1/admin/analytics/dashboard' do
    before do
      create_list(:page_view, 3)
      create_list(:project, 2)
      create(:blog_post, :published)
      create(:blog_post, :draft)
      create(:contact)
    end

    it 'returns dashboard analytics data' do
      get '/api/v1/admin/analytics/dashboard', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json[:success]).to be true
      expect(json_data).to include(
        :total_views, :unique_visitors, :views_by_date,
        :popular_pages, :recent_views, :summary
      )
    end

    it 'returns correct summary counts' do
      get '/api/v1/admin/analytics/dashboard', headers: headers, as: :json

      summary = json_data[:summary]
      expect(summary[:total_projects]).to eq(2)
      expect(summary[:total_blog_posts]).to eq(2)
      expect(summary[:published_blog_posts]).to eq(1)
      expect(summary[:draft_blog_posts]).to eq(1)
      expect(summary[:total_contacts]).to eq(1)
      expect(summary[:unread_contacts]).to eq(1)
    end

    it 'respects the days parameter' do
      create(:page_view, created_at: 60.days.ago)

      get '/api/v1/admin/analytics/dashboard?days=7', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      # The page view from 60 days ago should not be counted in 7-day window
      expect(json_data[:total_views]).to eq(3)
    end

    it 'clamps days parameter to valid range' do
      get '/api/v1/admin/analytics/dashboard?days=999', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'returns 401 without auth' do
      get '/api/v1/admin/analytics/dashboard', as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
