require 'rails_helper'

RSpec.describe 'Api::V1::Contacts', type: :request do
  describe 'POST /api/v1/contacts' do
    let(:valid_params) do
      {
        contact: {
          name: 'John Doe',
          email: 'john@example.com',
          subject: 'Test Subject',
          message: 'This is a test message with enough content.'
        }
      }
    end
    
    let(:invalid_params) do
      {
        contact: {
          name: '',
          email: 'invalid-email',
          message: 'short'
        }
      }
    end
    
    it 'creates a contact with valid params' do
      expect {
        post '/api/v1/contacts', params: valid_params
      }.to change(Contact, :count).by(1)
      
      expect(response).to have_http_status(:created)
      expect(json[:success]).to be true
    end
    
    it 'returns error with invalid params' do
      post '/api/v1/contacts', params: invalid_params
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:success]).to be false
      expect(json_errors).to be_present
    end
    
    it 'queues email notification job' do
      expect {
        post '/api/v1/contacts', params: valid_params
      }.to have_enqueued_job(EmailNotificationJob)
    end
  end
end