module Api
  module V1
    class ProjectsController < BaseController
      def index
        @projects = Project.ordered
        
        # Filter by featured if requested
        @projects = @projects.featured if params[:featured] == 'true'
        
        # Filter by tech stack if requested
        @projects = @projects.by_tech(params[:tech]) if params[:tech].present?
        
        # Pagination
        @projects = @projects.page(params[:page]).per(params[:per_page] || 10)
        
        render_success(
          ProjectResource.new(@projects).to_h,
          meta: pagination_meta(@projects)
        )
      end

      def show
        @project = Project.find(params[:id])

        render_success(
          ProjectResource.new(@project).to_h
        )
      end
    end
  end
end