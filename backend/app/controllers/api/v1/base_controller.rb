module Api
  module V1
    class BaseController < ApplicationController
      # Error handling
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request
      
      private
      
      # Pagination helper
      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
      
      # Standard success response
      def render_success(data, status: :ok, meta: {})
        render json: {
          success: true,
          data: data,
          meta: meta
        }, status: status
      end
      
      # Standard error response
      def render_error(message, status: :unprocessable_entity, errors: [])
        render json: {
          success: false,
          message: message,
          errors: errors
        }, status: status
      end
      
      # Error handlers
      def not_found(exception)
        render_error(exception.message, status: :not_found)
      end
      
      def unprocessable_entity(exception)
        render_error(
          'Validation failed',
          status: :unprocessable_entity,
          errors: exception.record.errors.full_messages
        )
      end
      
      def bad_request(exception)
        render_error(exception.message, status: :bad_request)
      end
    end
  end
end