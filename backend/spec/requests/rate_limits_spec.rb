require 'rails_helper'

RSpec.describe 'Rate limits', type: :request do
  let(:message) { 'Rate limit exceeded. Try again later.' }

  describe 'admin login' do
    let!(:admin) { create(:admin) }
    let(:wrong_password) { { email: admin.email, password: 'wrong_password_123' } }

    it 'returns 429 on the 6th attempt in 15 minutes, with or without a trailing slash' do
      5.times { post '/api/v1/admin/auth/login/', params: wrong_password, as: :json }
      expect(response).to have_http_status(:unauthorized)

      post '/api/v1/admin/auth/login/', params: wrong_password, as: :json

      expect(response).to have_http_status(:too_many_requests)
      expect(json[:success]).to be false
      expect(json[:message]).to eq(message)
      expect(response.headers['Retry-After']).to eq('900')
    end
  end

  describe 'token refresh' do
    it 'returns 429 on the 11th refresh in a minute' do
      10.times { post '/api/v1/admin/auth/refresh', as: :json }
      expect(response).to have_http_status(:unauthorized)

      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:too_many_requests)
      expect(json[:message]).to eq(message)
      expect(response.headers['Retry-After']).to eq('60')
    end
  end

  describe 'login and refresh counters' do
    let!(:admin) { create(:admin) }
    let(:wrong_password) { { email: admin.email, password: 'wrong_password_123' } }

    it 'does not let refreshes spend the login budget' do
      5.times { post '/api/v1/admin/auth/refresh', as: :json }

      post '/api/v1/admin/auth/login', params: wrong_password, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'keeps counting logins after the shorter refresh window expires' do
      post '/api/v1/admin/auth/refresh', as: :json
      4.times { post '/api/v1/admin/auth/login', params: wrong_password, as: :json }

      travel 61.seconds do
        post '/api/v1/admin/auth/refresh', as: :json
        post '/api/v1/admin/auth/login', params: wrong_password, as: :json
        expect(response).to have_http_status(:unauthorized)

        post '/api/v1/admin/auth/login', params: wrong_password, as: :json
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe 'contact form' do
    let(:contact) do
      { contact: { name: 'John Doe', email: 'john@example.com', message: 'This is a test message with enough content.' } }
    end

    it 'returns 429 on the 6th submission in 15 minutes and keeps the first five' do
      5.times { post '/api/v1/contacts/', params: contact, as: :json }
      expect(response).to have_http_status(:created)

      post '/api/v1/contacts/', params: contact, as: :json

      expect(response).to have_http_status(:too_many_requests)
      expect(json[:message]).to eq(message)
      expect(response.headers['Retry-After']).to eq('900')
      expect(Contact.count).to eq(5)
    end

    it 'does not route a .json suffix at all' do
      6.times { post '/api/v1/contacts.json', params: contact, as: :json }

      expect(response).to have_http_status(:not_found)
      expect(Contact.count).to eq(0)
    end
  end

  describe 'analytics tracking' do
    it 'returns 429 on the 21st page view in a minute and keeps the first twenty' do
      20.times { post '/api/v1/analytics/track', params: { path: '/' } }
      expect(response).to have_http_status(:created)

      post '/api/v1/analytics/track', params: { path: '/' }

      expect(response).to have_http_status(:too_many_requests)
      expect(json[:message]).to eq(message)
      expect(response.headers['Retry-After']).to eq('60')
      expect(PageView.count).to eq(20)
    end
  end

  describe 'general throttle' do
    it 'returns 429 on the 301st request in 5 minutes' do
      300.times { get '/health' }
      expect(response).to have_http_status(:ok)

      get '/health'

      expect(response).to have_http_status(:too_many_requests)
      expect(json).to eq(success: false, message: message)
    end
  end

  describe 'forged X-Forwarded-For' do
    it 'cannot get another address blocked by probing with it' do
      3.times { get '/health?x=/etc/passwd', headers: { 'X-Forwarded-For' => '203.0.113.9' } }

      get '/api/v1/projects', headers: { 'X-Forwarded-For' => '203.0.113.9' }

      expect(response).to have_http_status(:ok)
    end
  end
end
