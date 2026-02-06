require 'rails_helper'

RSpec.describe 'Api::V1::Experiences', type: :request do
  describe 'GET /api/v1/experiences' do
    let!(:experiences) { create_list(:experience, 3) }
    let!(:current_experience) { create(:experience, :current) }
    
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
    
    it 'includes duration in response' do
      get '/api/v1/experiences'
      
      expect(json_data.first).to have_key(:duration)
    end
  end
end