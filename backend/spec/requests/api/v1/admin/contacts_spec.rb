require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Contacts', type: :request do
  let!(:admin) { create(:admin) }
  let(:headers) { auth_headers(admin) }

  describe 'GET /api/v1/admin/contacts' do
    before do
      create_list(:contact, 2)
      create(:contact, :read)
      create(:contact, :archived)
    end

    it 'returns all contacts with pagination' do
      get '/api/v1/admin/contacts', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(4)
      expect(json_meta).to include(:current_page, :total_pages, :total_count)
    end

    it 'filters by status' do
      get '/api/v1/admin/contacts?status=new', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data.size).to eq(2)
      expect(json_data).to all(include(status: 'new'))
    end

    it 'returns 401 without auth' do
      get '/api/v1/admin/contacts', as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/admin/contacts/:id' do
    let!(:contact) { create(:contact) }

    it 'returns the contact' do
      get "/api/v1/admin/contacts/#{contact.id}", headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:id]).to eq(contact.id)
      expect(json_data[:name]).to eq(contact.name)
      expect(json_data[:message]).to eq(contact.message)
    end
  end

  describe 'PATCH /api/v1/admin/contacts/:id' do
    let!(:contact) { create(:contact) }

    it 'updates the contact status' do
      patch "/api/v1/admin/contacts/#{contact.id}",
            params: { contact: { status: 'read' } },
            headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_data[:status]).to eq('read')
      expect(contact.reload.status).to eq('read')
    end

    it 'rejects invalid status values' do
      patch "/api/v1/admin/contacts/#{contact.id}",
            params: { contact: { status: 'invalid' } },
            headers: headers, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'DELETE /api/v1/admin/contacts/:id' do
    let!(:contact) { create(:contact) }

    it 'deletes the contact' do
      expect {
        delete "/api/v1/admin/contacts/#{contact.id}", headers: headers, as: :json
      }.to change(Contact, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_data[:message]).to eq('Contact deleted')
    end
  end
end
