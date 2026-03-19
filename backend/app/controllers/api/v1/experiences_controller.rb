module Api
  module V1
    class ExperiencesController < BaseController
      def index
        @experiences = Experience.ordered
        
        # Filter by type if requested
        @experiences = @experiences.work if params[:type] == 'work'
        @experiences = @experiences.education if params[:type] == 'education'

        # Filter by current/past if requested
        @experiences = @experiences.current if params[:current] == 'true'
        @experiences = @experiences.past if params[:past] == 'true'
        
        # Pagination
        @experiences = @experiences.page(params[:page]).per(params[:per_page] || 20)
        
        render_success(
          ExperienceResource.new(@experiences).to_h,
          meta: pagination_meta(@experiences)
        )
      end
    end
  end
end