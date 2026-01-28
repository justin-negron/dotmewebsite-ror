module Api
  module V1
    class ExperiencesController < BaseController
      def index
        @experiences = Experience.ordered
        
        # Filter by current/past if requested
        @experiences = @experiences.current if params[:current] == 'true'
        @experiences = @experiences.past if params[:past] == 'true'
        
        # Pagination
        @experiences = @experiences.page(params[:page]).per(params[:per_page] || 20)
        
        render_success(
          ActiveModelSerializers::SerializableResource.new(@experiences).as_json,
          meta: pagination_meta(@experiences)
        )
      end
    end
  end
end