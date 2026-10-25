require 'rails_helper'

RSpec.describe 'Api::V1::Analytics::Analytics', type: :request do
  describe 'POST /api/v1/analytics/track' do
    let(:valid_params) do
      {
        path: '/projects'
      }
    end

    it 'creates a page view record' do
      expect {
        post '/api/v1/analytics/track', params: valid_params
      }.to change(PageView, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json[:success]).to be true
    end

    it 'captures the path' do
      post '/api/v1/analytics/track', params: { path: '/blog' }

      page_view = PageView.last
      expect(page_view.path).to eq('/blog')
    end

    it 'captures the user agent' do
      post '/api/v1/analytics/track',
           params: valid_params,
           headers: { 'User-Agent' => 'Mozilla/5.0 Chrome' }

      expect(PageView.last.user_agent).to eq('Mozilla/5.0 Chrome')
    end

    it 'stores a daily-salted hash of the visitor address instead of the address' do
      travel_to Time.zone.local(2026, 1, 15, 12, 0, 0) do
        post '/api/v1/analytics/track', params: valid_params, headers: { 'X-Forwarded-For' => '203.0.113.7' }
      end

      page_view = PageView.last
      expect(page_view.visitor_hash).to eq(PageView.visitor_hash_for('203.0.113.7', Date.new(2026, 1, 15)))
      expect(page_view.attributes).not_to have_key('ip_address')
    end

    it 'captures referrer' do
      post '/api/v1/analytics/track',
           params: valid_params.merge(referrer: 'https://google.com')

      page_view = PageView.last
      expect(page_view.referrer).to eq('https://google.com')
    end

    it 'caps the path, referrer and user agent at 512 characters' do
      post '/api/v1/analytics/track',
           params: { path: '/' + 'a' * 3000, referrer: 'https://example.com/' + 'b' * 3000 },
           headers: { 'User-Agent' => 'Mozilla/5.0 ' + 'c' * 3000 }

      page_view = PageView.last
      expect(page_view.path.length).to eq(512)
      expect(page_view.referrer.length).to eq(512)
      expect(page_view.user_agent.length).to eq(512)
    end

    it 'refuses a path that is not a site path' do
      expect {
        post '/api/v1/analytics/track', params: { path: 'https://evil.example/x' }
      }.not_to change(PageView, :count)

      expect(response).to have_http_status(:bad_request)
      expect(json[:message]).to eq('Invalid path')
    end
  end
end
