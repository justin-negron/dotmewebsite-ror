require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Experiences', type: :request do
  let!(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }

  describe 'GET /api/v1/admin/experiences' do
    before do
      create_list(:experience, 2)
      create(:experience, experience_type: 'education')
    end

    it 'returns all experiences with pagination' do
      get '/api/v1/admin/experiences', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json[:success]).to be true
      expect(json_data.size).to eq(3)
      expect(json_meta).to include(:current_page, :total_pages, :total_count)
    end

    it 'filters by experience type' do
      get '/api/v1/admin/experiences?type=education', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(1)
      expect(json_data.first[:experience_type]).to eq('education')
    end

    it 'returns 401 without auth' do
      get '/api/v1/admin/experiences', as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/admin/experiences/:id' do
    let!(:experience) { create(:experience) }

    it 'returns the experience' do
      get "/api/v1/admin/experiences/#{experience.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:id]).to eq(experience.id)
      expect(json_data[:company]).to eq(experience.company)
    end

    it 'returns 404 for non-existent experience' do
      get '/api/v1/admin/experiences/99999', headers: headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/admin/experiences' do
    let(:valid_params) do
      {
        experience: {
          company: 'Acme Corp',
          position: 'Senior Developer',
          description: 'Built awesome things',
          experience_type: 'work',
          start_date: '2023-01-01',
          technologies: ['Ruby', 'Rails']
        }
      }
    end

    it 'creates an experience and returns 201' do
      expect {
        post '/api/v1/admin/experiences', params: valid_params, headers: headers, as: :json
      }.to change(Experience, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_data[:company]).to eq('Acme Corp')
    end

    it 'returns 422 for invalid params' do
      post '/api/v1/admin/experiences',
           params: { experience: { position: 'No company' } },
           headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'PATCH /api/v1/admin/experiences/:id' do
    let!(:experience) { create(:experience, company: 'Old Corp') }

    it 'updates the experience' do
      patch "/api/v1/admin/experiences/#{experience.id}",
            params: { experience: { company: 'New Corp' } },
            headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:company]).to eq('New Corp')
    end

    it 'validates end_date is after start_date' do
      patch "/api/v1/admin/experiences/#{experience.id}",
            params: { experience: { end_date: '2000-01-01', start_date: '2023-01-01' } },
            headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'DELETE /api/v1/admin/experiences/:id' do
    let!(:experience) { create(:experience) }

    it 'deletes the experience' do
      expect {
        delete "/api/v1/admin/experiences/#{experience.id}", headers: headers, as: :json
      }.to change(Experience, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_data[:message]).to eq('Experience deleted')
    end
  end
end
