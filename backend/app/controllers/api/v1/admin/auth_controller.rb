module Api
  module V1
    module Admin
      class AuthController < Api::V1::BaseController
        before_action :authenticate_admin!, only: [:logout]

        # POST /api/v1/admin/auth/login
        def login
          admin = ::Admin.find_by(email: params[:email])

          unless admin&.authenticate(params[:password])
            return render_error('Invalid email or password', status: :unauthorized)
          end

          access_token = JwtService.encode_access_token(admin)
          refresh_token = JwtService.encode_refresh_token(admin)

          set_refresh_cookie(refresh_token)

          render_success({
            access_token: access_token,
            admin: AdminResource.new(admin).to_h
          })
        end

        # POST /api/v1/admin/auth/refresh
        def refresh
          refresh_token = cookies.signed[:refresh_token]
          return render_error('Missing refresh token', status: :unauthorized) unless refresh_token

          payload = JwtService.decode(refresh_token)
          return render_error('Invalid token type', status: :unauthorized) unless payload['type'] == 'refresh'

          admin = ::Admin.find(payload['admin_id'])

          unless admin.refresh_token_valid?(payload['jti'])
            admin.invalidate_refresh_token!
            delete_refresh_cookie
            return render_error('Refresh token revoked', status: :unauthorized)
          end

          # Rotate: issue new token pair, invalidate old refresh JTI
          access_token = JwtService.encode_access_token(admin)
          new_refresh_token = JwtService.encode_refresh_token(admin)

          set_refresh_cookie(new_refresh_token)

          render_success({
            access_token: access_token,
            admin: AdminResource.new(admin).to_h
          })
        rescue ActiveRecord::RecordNotFound
          render_error('Admin not found', status: :unauthorized)
        rescue JwtService::AuthenticationError => e
          delete_refresh_cookie
          render_error(e.message, status: :unauthorized)
        end

        # DELETE /api/v1/admin/auth/logout
        def logout
          current_admin.invalidate_refresh_token!
          delete_refresh_cookie
          render_success({ message: 'Logged out successfully' })
        end

        private

        def authenticate_admin!
          token = extract_token_from_header
          raise JwtService::AuthenticationError, 'Missing authorization header' unless token

          payload = JwtService.decode(token)
          raise JwtService::AuthenticationError, 'Invalid token type' unless payload['type'] == 'access'

          @current_admin = ::Admin.find(payload['admin_id'])
        rescue ActiveRecord::RecordNotFound
          render_error('Admin not found', status: :unauthorized)
        rescue JwtService::AuthenticationError => e
          render_error(e.message, status: :unauthorized)
        end

        def current_admin
          @current_admin
        end

        def extract_token_from_header
          header = request.headers['Authorization']
          header&.match(/\ABearer (.+)\z/)&.captures&.first
        end

        def set_refresh_cookie(token)
          cookies.signed[:refresh_token] = {
            value: token,
            httponly: true,
            secure: Rails.env.production?,
            same_site: Rails.env.production? ? :strict : :lax,
            expires: 7.days.from_now,
            path: '/api/v1/admin/auth'
          }
        end

        def delete_refresh_cookie
          cookies.delete(:refresh_token, path: '/api/v1/admin/auth')
        end
      end
    end
  end
end
