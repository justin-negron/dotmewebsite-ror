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
      ruby_project = create(:project, tech_stack: ['Ruby', 'Rails'])
      js_project = create(:project, tech_stack: ['JavaScript', 'React'])
      
      get '/api/v1/projects?tech=Ruby'
      
      expect(response).to have_http_status(:success)
      expect(json_data.size).to eq(1)
      expect(json_data.first[:id]).to eq(ruby_project.id)
    end
  end
end