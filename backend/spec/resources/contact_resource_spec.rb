require 'rails_helper'

RSpec.describe ContactResource do
  describe 'serialization' do
    it 'includes all attributes' do
      contact = create(:contact)
      result = ContactResource.new(contact).to_h

      expect(result["id"]).to eq(contact.id)
      expect(result["name"]).to eq(contact.name)
      expect(result["email"]).to eq(contact.email)
      expect(result["subject"]).to eq(contact.subject)
      expect(result["message"]).to eq(contact.message)
      expect(result["status"]).to eq(contact.status)
    end

    it 'formats created_at when present' do
      contact = create(:contact)
      result = ContactResource.new(contact).to_h

      expect(result["created_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil created_at' do
      contact = build(:contact, created_at: nil)
      result = ContactResource.new(contact).to_h

      expect(result["created_at"]).to be_nil
    end
  end
end
