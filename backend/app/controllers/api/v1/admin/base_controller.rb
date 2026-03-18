module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :authenticate_admin!

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
      end
    end
  end
end
