require 'rails_helper'

RSpec.describe 'Api::V1::Projects', type: :request do
  describe 'GET /api/v1/projects' do
    it 'returns all projects' do
      # Clean slate - create exactly what we're testing
      Project.destroy_all
      create_list(:project, 3)
      create(:project, :featured)

      get '/api/v1/projects'

      expect(response).to have_http_status(:success)
      expect(json[:success]).to be true
      expect(json_data.size).to eq(4)
    end

    it 'returns only featured projects when filtered' do
      Project.destroy_all
      create_list(:project, 2)
      featured = create(:project, :featured)

      get '/api/v1/projects?featured=true'

      expect(response).to have_http_status(:success)
      expect(json_data.size).to eq(1)
      expect(json_data.first[:featured]).to be true
    end

    it 'includes pagination meta' do
      get '/api/v1/projects'

      expect(json_meta).to include(:current_page, :total_pages, :total_count)
    end

    it 'clamps per_page=0 to one row per page' do
      Project.destroy_all
      create(:project)

      get '/api/v1/projects', params: { per_page: 0 }

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(1)
      expect(json_meta[:total_pages]).to eq(1)
    end

    it 'falls back to the default page size for an array per_page' do
      Project.destroy_all
      create_list(:project, 11)

      get '/api/v1/projects?per_page[]=5'

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(10)
    end

    it 'falls back to the default page size for a hash per_page' do
      Project.destroy_all
      create_list(:project, 11)

      get '/api/v1/projects?per_page[a]=5'

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(10)
    end

    it 'clamps a non-numeric per_page to one row per page' do
      Project.destroy_all
      create_list(:project, 2)

      get '/api/v1/projects', params: { per_page: 'abc' }

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(1)
    end

    it 'falls back to page 1 for an array page' do
      get '/api/v1/projects?page[]=2'

      expect(response).to have_http_status(:ok)
      expect(json_meta[:current_page]).to eq(1)
    end

    it 'falls back to page 1 for a hash page' do
      get '/api/v1/projects?page[a]=2'

      expect(response).to have_http_status(:ok)
      expect(json_meta[:current_page]).to eq(1)
    end
  end

  describe 'GET /api/v1/projects/:id' do
    let(:project) { create(:project) }

    it 'returns a specific project' do
      get "/api/v1/projects/#{project.id}"

      expect(response).to have_http_status(:success)
      expect(json_data[:id]).to eq(project.id)
      expect(json_data[:title]).to eq(project.title)
    end

    it 'returns 404 for non-existent project' do
      get '/api/v1/projects/99999'

      expect(response).to have_http_status(:not_found)
      expect(json[:success]).to be false
    end
  end

  describe 'filtering by tech stack' do
    it 'filters projects by technology' do
      ruby_project = create(:project, tech_stack: [ 'Ruby', 'Rails' ])
      js_project = create(:project, tech_stack: [ 'JavaScript', 'React' ])

      get '/api/v1/projects?tech=Ruby'

      expect(response).to have_http_status(:success)
      expect(json_data.size).to eq(1)
      expect(json_data.first[:id]).to eq(ruby_project.id)
    end
  end
end
