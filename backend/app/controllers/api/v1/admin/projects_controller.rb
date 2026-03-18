module Api
  module V1
    module Admin
      class ProjectsController < BaseController
        before_action :set_project, only: [:show, :update, :destroy]

        def index
          projects = Project.ordered.page(params[:page]).per(params[:per_page] || 20)
          render_success(ProjectResource.new(projects).to_h, meta: pagination_meta(projects))
        end

        def show
          render_success(ProjectResource.new(@project).to_h)
        end

        def create
          project = Project.create!(project_params)
          render_success(ProjectResource.new(project).to_h, status: :created)
        end

        def update
          @project.update!(project_params)
          render_success(ProjectResource.new(@project).to_h)
        end

        def destroy
          @project.destroy!
          render_success({ message: 'Project deleted' })
        end

        private

        def set_project
          @project = Project.find(params[:id])
        end

        def project_params
          params.require(:project).permit(
            :title, :description, :featured, :display_order,
            :github_url, :live_url, :image_url, tech_stack: []
          )
        end
      end
    end
  end
end
