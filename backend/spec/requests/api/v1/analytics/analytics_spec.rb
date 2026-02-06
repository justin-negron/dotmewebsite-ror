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
    
    it 'captures user agent from request' do
      post '/api/v1/analytics/track', 
           params: valid_params,
           headers: { 'User-Agent' => 'Mozilla/5.0 Chrome' }
      
      page_view = PageView.last
      expect(page_view.user_agent).to include('Chrome')
    end
    
    it 'captures IP address' do
      post '/api/v1/analytics/track', params: valid_params
      
      page_view = PageView.last
      expect(page_view.ip_address).to be_present
    end
    
    it 'captures referrer' do
      post '/api/v1/analytics/track',
           params: valid_params,
           headers: { 'Referer' => 'https://google.com' }
      
      page_view = PageView.last
      expect(page_view.referrer).to eq('https://google.com')
    end
  end
end