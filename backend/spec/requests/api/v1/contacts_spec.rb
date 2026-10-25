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

    it 'creates a contact from the flat JSON body the contact form sends' do
      post '/api/v1/contacts',
           params: { name: 'Ada Lovelace', email: 'ada@example.com', subject: 'Hi', message: 'Hello there, Justin!' },
           as: :json

      expect(response).to have_http_status(:created)
      expect(Contact.last.email).to eq('ada@example.com')
      expect(json_data[:message]).to eq('Thank you for your message! I will get back to you soon :)')
    end

    it 'returns every validation error with invalid params' do
      post '/api/v1/contacts', params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json[:success]).to be false
      expect(json[:message]).to eq('Failed to send message')
      expect(json_errors).to contain_exactly(
        "Name can't be blank", 'Email is invalid', 'Message is too short (minimum is 10 characters)'
      )
    end

    it 'returns 400 for a malformed JSON body' do
      post '/api/v1/contacts', params: '{"contact":', headers: { 'CONTENT_TYPE' => 'application/json' }

      expect(response).to have_http_status(:bad_request)
      expect(json[:success]).to be false
    end

    it 'queues the owner notification for the new contact on the mailers queue' do
      post '/api/v1/contacts', params: valid_params

      expect(EmailNotificationJob).to have_been_enqueued.with(Contact.last.id).on_queue('mailers')
    end
  end
end
