require 'rails_helper'

RSpec.describe 'Api::V1::Experiences', type: :request do
  describe 'GET /api/v1/experiences' do
    let!(:experiences) { create_list(:experience, 3) }
    let!(:current_experience) { create(:experience, :current) }

    it 'falls back to page 1 for an array page' do
      get '/api/v1/experiences?page[]=2'

      expect(response).to have_http_status(:ok)
      expect(json_meta[:current_page]).to eq(1)
    end

    it 'falls back to page 1 for a hash page' do
      get '/api/v1/experiences?page[a]=2'

      expect(response).to have_http_status(:ok)
      expect(json_meta[:current_page]).to eq(1)
    end

    it 'returns all experiences' do
      get '/api/v1/experiences'

      expect(response).to have_http_status(:success)
      expect(json[:success]).to be true
      expect(json_data.size).to eq(4)
    end

    it 'filters by current experiences' do
      get '/api/v1/experiences?current=true'

      expect(response).to have_http_status(:success)
      expect(json_data.size).to eq(1)
      expect(json_data.first[:current]).to be true
    end

    it 'filters by past experiences' do
      get '/api/v1/experiences?past=true'

      expect(response).to have_http_status(:success)
      expect(json_data.size).to eq(3)
      expect(json_data.first[:current]).to be false
    end

    it 'includes pagination meta' do
      get '/api/v1/experiences'

      expect(json_meta).to include(:current_page, :total_pages, :total_count)
    end

    it 'orders by start_date descending' do
      oldest = create(:experience, start_date: 3.years.ago)
      newest = create(:experience, start_date: 1.year.ago)

      get '/api/v1/experiences'

      experiences = json_data
      expect(experiences.first[:id]).to eq(newest.id)
    end

    it 'includes the formatted duration in the response' do
      experience = create(:experience, start_date: Date.new(2023, 3, 1), end_date: Date.new(2024, 5, 1))

      get '/api/v1/experiences'

      row = json_data.find { |e| e[:id] == experience.id }
      expect(row[:duration]).to eq('March 2023 - May 2024')
    end
  end
end
