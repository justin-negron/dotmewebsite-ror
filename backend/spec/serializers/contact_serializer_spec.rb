require 'rails_helper'

RSpec.describe ContactSerializer do
  describe 'serialization' do
    it 'includes all attributes' do
      contact = create(:contact)
      serializer = ContactSerializer.new(contact)
      serializable = serializer.serializable_hash
      
      expect(serializable[:id]).to eq(contact.id)
      expect(serializable[:name]).to eq(contact.name)
      expect(serializable[:email]).to eq(contact.email)
      expect(serializable[:subject]).to eq(contact.subject)
      expect(serializable[:message]).to eq(contact.message)
      expect(serializable[:status]).to eq(contact.status)
    end
    
    it 'formats created_at when present' do
      contact = create(:contact)
      serializer = ContactSerializer.new(contact)
      serializable = serializer.serializable_hash
      
      expect(serializable[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
    
    it 'handles nil created_at' do
      contact = build(:contact, created_at: nil)
      serializer = ContactSerializer.new(contact)
      serializable = serializer.serializable_hash
      
      expect(serializable[:created_at]).to be_nil
    end
  end
end