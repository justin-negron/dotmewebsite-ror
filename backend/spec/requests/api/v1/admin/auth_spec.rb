require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Auth', type: :request do
  let!(:admin) { create(:admin) }
  let(:valid_params) { { email: admin.email, password: 'secure_password_123' } }
  let(:uuid) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

  def signed_refresh_cookie(token)
    jar = ActionDispatch::TestRequest.create.cookie_jar
    jar.signed[:refresh_token] = token
    jar[:refresh_token]
  end

  describe 'POST /api/v1/admin/auth/login' do
    context 'with valid credentials' do
      it 'returns an access token for the admin and the admin data' do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        expect(json[:success]).to be true
        expect(JwtService.decode(json_data[:access_token])).to include('admin_id' => admin.id, 'type' => 'access')
        expect(json_data[:admin]).to include(email: admin.email)
      end

      it 'does not expose sensitive fields in admin data' do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json

        admin_data = json_data[:admin]
        expect(admin_data).not_to have_key('password_digest')
        expect(admin_data).not_to have_key('refresh_token_jti')
        expect(admin_data).not_to have_key('refresh_token_exp')
      end

      it 'sets an httpOnly refresh cookie scoped to the auth path' do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json

        cookie = response.headers['Set-Cookie']
        expect(cookie).to include('refresh_token')
        expect(cookie.downcase).to include('httponly')
        expect(cookie).to include('path=/api/v1/admin/auth')
        expect(cookie).to match(/samesite=lax/i)
      end

      it 'stores a 7-day refresh token JTI on the admin record' do
        freeze_time do
          post '/api/v1/admin/auth/login', params: valid_params, as: :json

          expect(admin.reload.refresh_token_jti).to match(uuid)
          expect(admin.refresh_token_exp).to be_within(5.seconds).of(7.days.from_now)
        end
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

      it 'hashes the password even when the email is unknown' do
        expect(BCrypt::Password).to receive(:new).once.and_call_original

        post '/api/v1/admin/auth/login',
             params: { email: 'nobody@example.com', password: 'whatever_1234' },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/admin/auth/refresh' do
    context 'after logging in' do
      before do
        post '/api/v1/admin/auth/login', params: valid_params, as: :json
      end

      it 'returns a new access token when the refresh token is valid' do
        post '/api/v1/admin/auth/refresh', as: :json

        expect(response).to have_http_status(:ok)
        expect(json[:success]).to be true
        expect(JwtService.decode(json_data[:access_token])).to include('admin_id' => admin.id, 'type' => 'access')
        expect(json_data[:admin]).to include(email: admin.email)
      end

      it 'rotates the refresh token JTI' do
        old_jti = admin.reload.refresh_token_jti

        post '/api/v1/admin/auth/refresh', as: :json

        expect(admin.reload.refresh_token_jti).to match(uuid)
        expect(admin.refresh_token_jti).not_to eq(old_jti)
      end

      it 'returns unauthorized without refresh cookie' do
        cookies[:refresh_token] = ''
        post '/api/v1/admin/auth/refresh', as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json[:message]).to eq('Missing refresh token')
      end

      it 'returns unauthorized and clears the cookie when the JTI has been invalidated' do
        admin.invalidate_refresh_token!

        post '/api/v1/admin/auth/refresh', as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json[:message]).to eq('Refresh token revoked')
        expect(response.headers['Set-Cookie']).to match(/refresh_token=;/)
      end

      it 'revokes the session when an already-rotated refresh token is replayed' do
        old_cookie = cookies[:refresh_token]
        post '/api/v1/admin/auth/refresh', as: :json
        expect(response).to have_http_status(:ok)

        cookies[:refresh_token] = old_cookie
        post '/api/v1/admin/auth/refresh', as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(json[:message]).to eq('Refresh token revoked')
        expect(admin.reload.refresh_token_jti).to be_nil
      end
    end

    it 'rejects an expired refresh token and clears the cookie' do
      token = travel_to(8.days.ago) { JwtService.encode_refresh_token(admin) }
      cookies[:refresh_token] = signed_refresh_cookie(token)

      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json[:message]).to eq('Token has expired')
      expect(response.headers['Set-Cookie']).to match(/refresh_token=;/)
    end

    it 'rejects a tampered refresh token and clears the cookie' do
      token = JwtService.encode_refresh_token(admin)
      cookies[:refresh_token] = signed_refresh_cookie(token[0...-5] + 'XXXXX')

      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json[:message]).to start_with('Invalid token:')
      expect(response.headers['Set-Cookie']).to match(/refresh_token=;/)
    end

    it 'rejects an access token sent as the refresh cookie' do
      cookies[:refresh_token] = signed_refresh_cookie(JwtService.encode_access_token(admin))

      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json[:message]).to eq('Invalid token type')
    end

    it 'rejects a refresh token whose admin was deleted' do
      token = JwtService.encode_refresh_token(admin)
      admin.destroy
      cookies[:refresh_token] = signed_refresh_cookie(token)

      post '/api/v1/admin/auth/refresh', as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json[:message]).to eq('Admin not found')
    end
  end

  describe 'DELETE /api/v1/admin/auth/logout' do
    it 'invalidates refresh token and returns success' do
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

      expect(response).to have_http_status(:ok)
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

    it 'rejects a token whose admin was deleted' do
      headers = auth_headers(admin)
      admin.destroy

      get '/api/v1/admin/projects', headers: headers, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json[:message]).to eq('Admin not found')
    end
  end
end
