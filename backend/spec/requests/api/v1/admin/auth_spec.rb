require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Auth', type: :request do
  let!(:admin) { create(:admin) }
  let(:valid_params) { { email: admin.email, password: 'secure_password_123' } }

  describe 'POST /api/v1/admin/auth/login' do
    context 'with valid credentials' do
      it 'returns access token and admin data' do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        expect(json[:success]).to be true
        expect(json_data[:access_token]).to be_present
        expect(json_data[:admin]).to include(email: admin.email)
      end

      it 'does not expose sensitive fields in admin data' do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json

        admin_data = json_data[:admin]
        expect(admin_data).not_to have_key('password_digest')
        expect(admin_data).not_to have_key('refresh_token_jti')
        expect(admin_data).not_to have_key('refresh_token_exp')
      end

      it 'sets refresh token cookie' do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json

        cookie = response.headers['Set-Cookie']
        expect(cookie).to include('refresh_token')
        expect(cookie.downcase).to include('httponly')
      end

      it 'stores refresh token JTI on admin record' do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json

        expect(admin.reload.refresh_token_jti).to be_present
        expect(admin.reload.refresh_token_exp).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post '/api/v1/admin/auth/login',
             params: { email: admin.email, password: 'wrong_password_123' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json[:success]).to be false
      end

      it 'returns unauthorized for non-existent email' do
        post '/api/v1/admin/auth/login',
             params: { email: 'nobody@example.com', password: 'whatever_1234' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not reveal whether email exists' do
        post '/api/v1/admin/auth/login',
             params: { email: 'nobody@example.com', password: 'whatever_1234' },
             as: :json

        expect(json[:message]).to eq('Invalid email or password')
      end
    end
  end

  describe 'POST /api/v1/admin/auth/refresh' do
    before do
      # Login first to establish refresh cookie
      post '/api/v1/admin/auth/login', params: valid_params, as: :json
    end

    it 'returns new access token when refresh token is valid' do
      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:ok)
      expect(json[:success]).to be true
      expect(json_data[:access_token]).to be_present
      expect(json_data[:admin]).to include(email: admin.email)
    end

    it 'rotates the refresh token JTI' do
      old_jti = admin.reload.refresh_token_jti

      post '/api/v1/admin/auth/refresh', as: :json

      expect(admin.reload.refresh_token_jti).not_to eq(old_jti)
    end

    it 'returns unauthorized without refresh cookie' do
      # Clear the signed cookie by overwriting with an empty value
      cookies[:refresh_token] = ''
      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized when JTI has been invalidated' do
      admin.invalidate_refresh_token!

      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/admin/auth/logout' do
    it 'invalidates refresh token and returns success' do
      # Login first
      post '/api/v1/admin/auth/login', params: valid_params, as: :json
      token = json_data[:access_token]

      delete '/api/v1/admin/auth/logout',
             headers: { 'Authorization' => "Bearer #{token}" },
             as: :json

      expect(response).to have_http_status(:ok)
      expect(json[:success]).to be true
      expect(admin.reload.refresh_token_jti).to be_nil
    end

    it 'returns unauthorized without access token' do
      delete '/api/v1/admin/auth/logout', as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'protected endpoint access' do
    it 'allows access with valid token' do
      get '/api/v1/admin/projects',
          headers: auth_headers(admin),
          as: :json

      expect(response).not_to have_http_status(:unauthorized)
    end

    it 'rejects access without token' do
      get '/api/v1/admin/projects', as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects access with expired token' do
      token = travel_to(1.hour.ago) { JwtService.encode_access_token(admin) }

      get '/api/v1/admin/projects',
          headers: { 'Authorization' => "Bearer #{token}" },
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects access with refresh token (wrong type)' do
      refresh_token = JwtService.encode_refresh_token(admin)

      get '/api/v1/admin/projects',
          headers: { 'Authorization' => "Bearer #{refresh_token}" },
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
