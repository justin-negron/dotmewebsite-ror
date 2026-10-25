module Api
  module V1
    class BaseController < ApplicationController
      # Error handling
      rescue_from StandardError, with: :internal_server_error
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from ActionDispatch::Http::Parameters::ParseError, ActionController::BadRequest, with: :bad_request

      # The default rate_limit raises, which the StandardError rescue would turn
      # into a 500. Rails keys the counter by name, so two unnamed throttles in
      # one controller share a counter; deriving the name from the action keeps
      # each throttle's count and window its own.
      def self.throttle(to:, within:, only:, name: Array(only).join("-"), **options)
        rate_limit(to: to, within: within, only: only, name: name, with: -> { rate_limited(within) }, **options)
      end

      private

      def rate_limited(within)
        response.set_header("Retry-After", within.to_i.to_s)
        render_error("Rate limit exceeded. Try again later.", status: :too_many_requests)
      end

      def per_page(default)
        raw = params[:per_page]
        raw = default unless raw.is_a?(String) || raw.is_a?(Integer)
        raw.to_i.clamp(1, 100)
      end

      def page_param
        raw = params[:page]
        raw if raw.is_a?(String) || raw.is_a?(Integer)
      end

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
      def render_error(message, status: :unprocessable_content, errors: [])
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
          "Validation failed",
          status: :unprocessable_content,
          errors: exception.record.errors.full_messages
        )
      end

      def bad_request(exception)
        render_error(exception.message, status: :bad_request)
      end

      def internal_server_error(exception)
        Rails.error.report(exception, handled: true)
        Rails.logger.error "Unhandled error: #{exception.class} — #{exception.message}\n#{exception.backtrace&.first(5)&.join("\n")}"
        render_error("An unexpected error occurred", status: :internal_server_error)
      end
    end
  end
end
