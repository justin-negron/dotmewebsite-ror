require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Projects', type: :request do
  let!(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }

  describe 'GET /api/v1/admin/projects' do
    before { create_list(:project, 3) }

    it 'returns all projects with pagination' do
      get '/api/v1/admin/projects', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json[:success]).to be true
      expect(json_data).to be_an(Array)
      expect(json_data.size).to eq(3)
      expect(json_meta).to include(:current_page, :total_pages, :total_count)
    end

    it 'returns 401 without auth' do
      get '/api/v1/admin/projects', as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/admin/projects/:id' do
    let!(:project) { create(:project) }

    it 'returns the project' do
      get "/api/v1/admin/projects/#{project.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:id]).to eq(project.id)
      expect(json_data[:title]).to eq(project.title)
    end

    it 'returns 404 for non-existent project' do
      get '/api/v1/admin/projects/99999', headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/admin/projects' do
    let(:valid_params) do
      {
        project: {
          title: 'New Project',
          description: 'A new project description',
          tech_stack: ['Ruby', 'Rails'],
          featured: true,
          github_url: 'https://github.com/user/repo'
        }
      }
    end

    it 'creates a project and returns 201' do
      expect {
        post '/api/v1/admin/projects', params: valid_params, headers: headers, as: :json
      }.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_data[:title]).to eq('New Project')
      expect(json_data[:featured]).to be true
    end

    it 'returns 422 for invalid params' do
      post '/api/v1/admin/projects',
           params: { project: { description: 'No title' } },
           headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:success]).to be false
    end

    it 'returns 401 without auth' do
      post '/api/v1/admin/projects', params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/admin/projects/:id' do
    let!(:project) { create(:project, title: 'Old Title') }

    it 'updates the project' do
      patch "/api/v1/admin/projects/#{project.id}",
            params: { project: { title: 'Updated Title' } },
            headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:title]).to eq('Updated Title')
      expect(project.reload.title).to eq('Updated Title')
    end

    it 'returns 422 for invalid update' do
      patch "/api/v1/admin/projects/#{project.id}",
            params: { project: { title: '' } },
            headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'DELETE /api/v1/admin/projects/:id' do
    let!(:project) { create(:project) }

    it 'deletes the project' do
      expect {
        delete "/api/v1/admin/projects/#{project.id}", headers: headers, as: :json
      }.to change(Project, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_data[:message]).to eq('Project deleted')
    end

    it 'returns 404 for non-existent project' do
      delete '/api/v1/admin/projects/99999', headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
