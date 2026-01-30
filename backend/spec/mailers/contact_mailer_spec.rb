require 'rails_helper'

RSpec.describe ContactMailer, type: :mailer do
  describe '#new_contact_notification' do
    let(:contact) { create(:contact, name: 'John Doe', email: 'john@example.com', subject: 'Test Subject', message: 'Test message') }
    let(:mail) { ContactMailer.new_contact_notification(contact.id) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('New Contact Form Submission: Test Subject')
      expect(mail.to).to eq([ENV.fetch('FROM_EMAIL', 'hello@justinnegron.dev')])
      expect(mail.from).to eq([ENV.fetch('FROM_EMAIL', 'hello@justinnegron.dev')])
      expect(mail.reply_to).to eq(['john@example.com'])
    end
    
    it 'includes contact name in body' do
      expect(mail.body.encoded).to match('John Doe')
    end
    
    it 'includes contact email in body' do
      expect(mail.body.encoded).to match('john@example.com')
    end
    
    it 'includes contact message in body' do
      expect(mail.body.encoded).to match('Test message')
    end
    
    it 'includes subject in body' do
      expect(mail.body.encoded).to match('Test Subject')
    end
  end
  
  describe '#submission_confirmation' do
    let(:contact) { create(:contact, name: 'John Doe', email: 'john@example.com', message: 'Test message') }
    let(:mail) { ContactMailer.submission_confirmation(contact.id) }
    
    it 'renders the headers' do
      expect(mail.subject).to eq('Thanks for reaching out!')
      expect(mail.to).to eq(['john@example.com'])
      expect(mail.from).to eq([ENV.fetch('FROM_EMAIL', 'hello@justinnegron.dev')])
    end
    
    it 'includes contact name in body' do
      expect(mail.body.encoded).to match('John Doe')
    end
    
    it 'includes thank you message' do
      expect(mail.body.encoded).to match('Thank you for contacting me')
    end
    
    it 'includes submitted message in body' do
      expect(mail.body.encoded).to match('Test message')
    end
  end
end
