module Api
  module V1
    module Admin
      class ExperiencesController < BaseController
        before_action :set_experience, only: [:show, :update, :destroy]

        def index
          experiences = Experience.ordered
          experiences = experiences.where(experience_type: params[:type]) if params[:type].present?
          experiences = experiences.page(params[:page]).per(params[:per_page] || 20)
          render_success(ExperienceResource.new(experiences).to_h, meta: pagination_meta(experiences))
        end

        def show
          render_success(ExperienceResource.new(@experience).to_h)
        end

        def create
          experience = Experience.create!(experience_params)
          render_success(ExperienceResource.new(experience).to_h, status: :created)
        end

        def update
          @experience.update!(experience_params)
          render_success(ExperienceResource.new(@experience).to_h)
        end

        def destroy
          @experience.destroy!
          render_success({ message: 'Experience deleted' })
        end

        private

        def set_experience
          @experience = Experience.find(params[:id])
        end

        def experience_params
          params.require(:experience).permit(
            :company, :position, :description, :experience_type,
            :display_order, :start_date, :end_date, technologies: []
          )
        end
      end
    end
  end
end
