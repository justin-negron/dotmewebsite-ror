require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:message) }
    
    it 'validates email format' do
      contact = build(:contact, email: 'invalid-email')
      expect(contact).not_to be_valid
      expect(contact.errors[:email]).to be_present
    end
    
    it 'validates message minimum length' do
      contact = build(:contact, message: 'short')
      expect(contact).not_to be_valid
      expect(contact.errors[:message]).to be_present
    end
  end
  
  describe 'enums' do
    it 'defines status enum' do
      expect(Contact.new).to respond_to(:status)
    end
  end
  
  describe 'scopes' do
    it 'returns unread contacts' do
      new_contact = create(:contact)
      read_contact = create(:contact, :read)
      
      expect(Contact.unread).to include(new_contact)
      expect(Contact.unread).not_to include(read_contact)
    end
    
    it 'orders by most recent first' do
      travel_to 3.days.ago do
        @old_contact = create(:contact)
      end
      
      travel_to 2.days.ago do
        @middle_contact = create(:contact)
      end
      
      travel_to 1.day.ago do
        @new_contact = create(:contact)
      end
      
      contacts = Contact.recent.to_a
      expect(contacts.first).to eq(@new_contact)
      expect(contacts.last).to eq(@old_contact)
    end
  end
  
  describe '#mark_as_read!' do
    it 'updates status to read' do
      contact = create(:contact)
      contact.mark_as_read!
      expect(contact.reload.status).to eq('read')
    end
  end
  
  describe '#mark_as_archived!' do
    it 'updates status to archived' do
      contact = create(:contact)
      contact.mark_as_archived!
      expect(contact.reload.status).to eq('archived')
    end
  end
  
  describe 'callbacks' do
    it 'queues email notification after create' do
      expect {
        create(:contact)
      }.to have_enqueued_job(EmailNotificationJob)
    end
  end
end
